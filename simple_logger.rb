class SimpleLogger
  LEVELS = %i( debug info warn error ).freeze

  def initialize(level: LEVELS.first, prefix: nil, labels: {}, appenders: [])
    @prefix    = prefix
    @labels    = sanitize_labels(labels)
    @appenders = appenders

    self.level = level
  end

  def level
    LEVELS.fetch(@level_idx)
  end

  def level=(level)
    @level_idx = LEVELS.index(level) or raise "unknown level: #{level.inspect}"
  end

  def [](prefix=nil, **labels)
    sublogger_class.new(
      level: level,
      prefix: append_prefix(prefix),
      labels: @labels.merge(sanitize_labels(labels)),
      appenders: @appenders,
    )
  end
  alias sub []

  LEVELS.each.with_index do |level, level_idx|
    eval <<-RUBY
      def #{level}(...)
        log(#{level_idx}, ...)
      end
    RUBY
  end

protected

  def sublogger_class
    self.class
  end

private

  def append_prefix(prefix)
    [@prefix, prefix].compact.
      tap { |arr| return if arr.empty? }.
      join ": "
  end

  def sanitize_labels(labels)
    labels.transform_values do |value|
      value = format_exception(value) if Exception === value
      value.to_s
    end
  end

  def log(level_idx, msg)
    if level_idx < @level_idx
      result = yield if block_given?
      return result
    end

    if block_given?
      append(level_idx, "#{msg}...")
      elapsed = measure { result = yield }
      sub(elapsed: format_duration(elapsed)).public_send(level, msg)
    else
      append(level_idx, msg)
    end

    result
  end

  def append(level_idx, msg)
    entry = @labels.merge(
      level: LEVELS.fetch(level_idx),
      msg: [@prefix, msg].compact.join(": "),
    ).freeze

    @appenders.each do |appender|
      appender.append(entry)
    end
  end

  def format_exception(e)
    causes = []
    loop do
      str = "#{e.class}"
      causes << str
      if !(s = e.to_s).empty? && s != str
        str << " (#{s})"
      end
      e = e.cause or break
    end
    causes.join(" < ")
  end

  def format_duration(duration)
    "%.2fs" % [duration]
  end

  def measure
    t0 = Time.now
    yield
    Time.now - t0
  end

  module Appenders
    class Logfmt
      def initialize(io)
        @io = io
        @mutex = Mutex.new
      end

      def append(entry)
        @mutex.synchronize { do_append(entry) }
      end

    private

      def do_append(entry)
        @io.write "#{format_entry entry}\n"
      end

      def format_entry(entry)
        msg = entry.fetch(:msg)

        result = "#{msg}"
        entry.each do |label, value|
          next if label == :msg
          value = %("#{value}") if /\s/ === value
          result << " #{label}=#{value}"
        end

        result
      end
    end

    class LogfmtWithLevels < Logfmt
      LEVELS_WIDTH = LEVELS.map(&:length).max

    private

      def format_entry(entry)
        msg = entry.fetch(:msg)
        level = entry.fetch(:level)

        msg = "%*s %s" % [LEVELS_WIDTH, level.upcase, msg]
        entry = entry.reject { |k,| k == :level }.merge(msg: msg)

        super(entry)
      end
    end
  end
end
