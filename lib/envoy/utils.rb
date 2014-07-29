module Envoy

  TRACE = 5
  DEBUG = 4
  INFO  = 3
  WARN  = 2
  ERROR = 1
  FATAL = 0

  VERBOSITIES = "FEWIDT"

  def self.verbosity
    @verbosity
  end

  def self.verbosity= (num)
    @verbosity = [0, [5, num].min].max
  end

  def self.log (level, text, io = STDERR)
    return unless io
    level = Envoy.const_get(level.upcase) unless level.is_a?(Numeric)
    return unless level <= verbosity
    message = [
      Time.now.strftime("%F %T"),
      VERBOSITIES[level],
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
