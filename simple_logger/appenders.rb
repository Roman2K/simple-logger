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

  class Logfmt
    def initialize(appender, **logfmt_opts)
      @appender = appender
      @logfmt_format = Formatters::Logfmt.new(**logfmt_opts)
    end

    def append(entry)
      @appender.append(format_entry(entry))
    end

  protected

    def format_entry(entry)
      @logfmt_format.format(entry)
    end
  end

  class LogfmtHuman < Logfmt
    LEVELS_WIDTH   = LEVELS.map(&:length).max
    DURATION_LABEL = :duration

  protected

    def format_entry(entry)
      entry = entry.dup

      format_values!(entry)

      entry.delete(:time)
      msg = entry.delete(:msg) or raise "missing `msg`"
      level = entry.delete(:level) or raise "missing `label`"

      labels = super(entry)
      msg = "%*s %s" % [LEVELS_WIDTH, level.upcase, msg]
      msg << " " << labels unless labels.empty?

      msg
    end

    def format_values!(entry)
      if value = entry[DURATION_LABEL]
        entry[DURATION_LABEL] = format_duration(value)
      end
    end

    def format_duration(value)
      return value unless Numeric === value

      if value < 1
        "%dms" % [value * 1000]
      else
        "%.2fs" % [value]
      end
    end
  end
end

end
