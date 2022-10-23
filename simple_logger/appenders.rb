class SimpleLogger

module Appenders
  # Example:
  #
  #   Appenders.
  #     pipe(:OpenTelemetryContext).
  #     pipe(:Logfmt).
  #     pipe(:stderr)
  #
  def self.pipe(...)
    Pipeline.new.pipe(...)
  end

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

  class Wrapper
    def initialize(appender)
      @appender = appender
    end

    def append(entry)
      @appender.append(entry)
    end
  end

  class WithMutex < Wrapper
    def initialize(*)
      super
      @mutex = Mutex.new
    end

    def append(entry)
      @mutex.synchronize do
        super
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

  class Logfmt < Wrapper
    def initialize(appender, **logfmt_opts)
      super(appender)
      @logfmt_format = Formatters::Logfmt.new(**logfmt_opts)
    end

    def append(entry)
      super(format_entry(entry))
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

  class Pipeline
    def initialize
      @stages = []
    end

    def pipe(stage, ...)
      case stage
      when /^[A-Z]/
        pipe(Appenders.const_get(stage), ...)
      when Class
        if stage < Wrapper
          @stages << -> appender {
            stage.new(appender, ...)
          }
          self
        else
          pipe(stage.new(...))
        end
      when /^[a-z]/
        pipe(Appenders.public_send(stage, ...))
      else
        to_appender(stage)
      end
    end

  private

    def to_appender(appender)
      @stages.reverse_each do |stage|
        appender = stage.(appender)
      end
      appender
    end
  end

  class OpenTelemetryContext < Wrapper
    def append(entry)
      super(entry.merge(open_telemetry_context_labels))
    end

  private

    def open_telemetry_context_labels
      span = OpenTelemetry::Trace.current_span

      return {} unless span.recording?

      { trace_id: span.context.hex_trace_id,
        span_id: span.context.hex_span_id, }
    end
  end
end

end
