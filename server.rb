require 'eventmachine'
require 'securerandom'
require 'rack'

require './protocol'

$reloader = Rack::Reloader.new(proc{}, 0)

module Trunk
  include Protocol
  
  def self.trunks
    @trunks ||= Hash.new{|h,k|h[k] = []}
  end
  
  def hosts
    @hosts ||= []
  end
  
  def channels
    @channels ||= {}
  end
  
  def receive_close id
    if chan = channels[id]
      chan.web.close_connection(true)
      channels.delete id
    end
  end
  
  def receive_start_tls
    send_object :start_tls
    start_tls
  end
  
  def receive_stream id, data
    channels[id].web.send_data data
  end
  
  def receive_options options
    @options = options
    hosts = @options[:hosts] || []
    hosts.delete_if do |label|
      if label == "s"
        send_object :message, "`s' is a reserved label"
        true
      elsif label =~ /\./
        send_object :message, "labels may not contain dots"
        true
      end
    end
    hosts << SecureRandom.hex(4) if hosts.empty?
    @hosts = hosts.each do |host|
      Trunk.trunks[host] << self
    end
    send_object :message, "hello #{hosts.join(", ")}"
  end
  
  def unbind
    hosts.each do |host|
      Trunk.trunks[host].delete self
    end
  end
  
end

class Channel
  
  attr_accessor :trunk, :web
  
  def initialize trunk, web, header
    @trunk = trunk
    @web = web
    @trunk.channels[id] = self
    @trunk.send_object :connection, id
    stream header
  end
  
  def stream data
    @trunk.send_object :stream, id, data
  end
  
  def id
    @id ||= SecureRandom.hex(4)
  end
  
end

module Web
  include EM::P::LineText2
  
  def initialize zone
    @zone = zone
    super()
  end
  
  def post_init
    @header = ""
  end
  
  def unbind
    @channel.trunk.channels.delete @channel.id if @channel
  end
  
  def receive_line line
    @header << line + "\r\n"
    if line =~ /^Host: ([^:]*)/
      host = $1
      begin
        raise "Request is not in #{@zone}" unless host.end_with?(@zone)
        host = host[0..-@zone.length]
        host = host.split(".").last
        trunk = Trunk.trunks[host].sample || raise("No trunk for #{host}#{@zone}")
        @channel = Channel.new(trunk, self, @header)
        set_text_mode
      rescue => e
        send_data "HTTP/1.0 500 Internal Server Error\r\n"
        send_data "Content-Type: text/plain\r\n"
        send_data "\r\n"
        send_data "#{e.message}.\r\n"
        close_connection true
      end
    end
  end
  
  def receive_binary_data data
    @channel.stream data
  end
  
end

unless EM.reactor_running?
  EM.run do
    EM.add_periodic_timer(0.1) do
      $reloader.(0)
    end
    EM.start_server "0.0.0.0", 8282, Trunk
    EM.start_server "0.0.0.0", 8181, Web, ".athens.p12a.org.uk"
  end
end

