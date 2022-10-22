class SimpleLogger
  dir = __dir__ + '/simple_logger'
  autoload :Appenders, dir + '/appenders'
  autoload :Formatters, dir + '/formatters'

  LEVELS = %i[debug info warn error].freeze

  def initialize(level: LEVELS.first, prefix: nil, labels: {}, appender: nil)
    @prefix   = prefix
    @labels   = sanitize_labels(labels)
    @appender = appender || Appenders::Logfmt.new(Appenders.stderr)

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
      appender: @appender,
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

  def append(level_idx, msg)
    entry = {
      time:  Time.now,
      level: LEVELS.fetch(level_idx),
      msg:   [@prefix, msg].compact.join(": "),
    }.merge(@labels).freeze

    @appender.append(entry)
  end

private

  def append_prefix(prefix)
    [@prefix, prefix].compact.
      tap { |arr| return if arr.empty? }.
      join ": "
  end

  def sanitize_labels(labels)
    labels.transform_values do |value|
      case value
      when Exception
        format_exception(value)
      else
        value
      end
    end
  end

  def log(level_idx, msg)
    if level_idx < @level_idx
      result = yield if block_given?
      return result
    end

    if block_given?
      append(level_idx, "#{msg}...")
      duration = measure { result = yield }
      sub(duration: duration).append(level_idx, msg)
    else
      append(level_idx, msg)
    end

    result
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

  def measure
    t0 = Time.now
    yield
    Time.now - t0
  end
end
