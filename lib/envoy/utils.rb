module Envoy

  TRACE = 5
  DEBUG = 4
  INFO  = 3
  WARN  = 2
  ERROR = 1
  FATAL = 0

  VERBOSITIES = "FEWIDT"

  class << self
    attr_accessor :verbosity
  end

  def self.log (level, text, io = STDERR)
    return unless io
    return unless level <= verbosity
    message = [
      Time.now.strftime("%F %T"),
      VERBOSITIES[level][0],
      text
    ].compact.join(" ")
    io.puts message
    io.flush
  end

  def self.find_file (name)
    dirs = Dir.pwd.split("/")
    r = dirs.reduce([]) do |m, x|
      [[*m[0], x], *m]
    end.map do |p|
      p.join("/") + "/#{name}"
    end.each do |p|
      return p if File.exist?(p)
    end
    false
  end

end
