class SimpleLogger

module Appenders
  def self.stderr
    stdio($stderr)
  end

  def self.stdio(io)
    appender = IO.new(io)

    if ::IO === io && io.fileno <= 2
      WithMutex.new(appender)
    else
      appender
    end
  end

  class Noop
    def append(entry)
    end
  end

  class WithMutex
    def initialize(appender)
      @appender = appender
      @mutex = Mutex.new
    end

    def append(entry)
      @mutex.synchronize do
        @appender.append(entry)
      end
    end
  end

  class IO
    def initialize(io)
      @io = io
    end

    def append(entry)
      @io.write "#{entry}\n"
    end
  end

  # See https://brandur.org/logfmt
  class Logfmt
    def self.format_labels(labels)
      labels.map { |label, value|
        value = value.to_s
        value = %("#{value}") if value =~ /\s/
        "#{label}=#{value}"
      }.join " "
    end

    def initialize(appender)
      @appender = appender
    end

    def append(entry)
      @appender.append(self.class.format_labels(entry))
    end
  end

  class LogfmtHuman
    LEVELS_WIDTH = LEVELS.map(&:length).max

    def initialize(appender)
      @appender = appender
    end

    def append(entry)
      entry = entry.dup
      msg = entry.delete(:msg) or raise "missing `msg`"
      level = entry.delete(:level) or raise "missing `label`"

      labels = Logfmt.format_labels(entry)
      msg = "%*s %s" % [LEVELS_WIDTH, level.upcase, msg]
      msg << " " << labels unless labels.empty?

      @appender.append(msg)
    end
  end
end

end
