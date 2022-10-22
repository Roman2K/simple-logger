module SimpleLogger::Formatters

# See https://brandur.org/logfmt
class Logfmt
  DEFAULT_TIME_FORMAT = :RFC3339Nano

  def initialize(time_format: DEFAULT_TIME_FORMAT)
    @time_format = TimeFormats.const_get(time_format).new
  end

  def format(labels)
    labels.map { format_pair(_1, _2) }.join " "
  end

private

  def format_pair(label, value)
    result = "#{format_label(label)}"
    return result if value == true
    result << "=" << format_value(value)
  end

  RE_QUOTING_NEEDED = /\s|[[:cntrl:]]/

  def format_label(label)
    label = label.to_s
    raise "invalid label: #{label.inspect}" if label =~ RE_QUOTING_NEEDED
    label
  end

  def format_value(value)
    value = @time_format.format(value) if Time === value
    value = "#{value}"
    value = value.dump if value =~ RE_QUOTING_NEEDED
    value
  end
end

# See https://grafana.com/docs/loki/latest/clients/promtail/stages/timestamp/#reference-time
module TimeFormats
  class RFC3339Nano
    FORMAT = "%FT%T.%9N%:z".freeze

    def format(time)
      time.strftime FORMAT
    end
  end
end

end
