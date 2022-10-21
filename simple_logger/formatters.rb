module SimpleLogger::Formatters

# See https://brandur.org/logfmt
class Logfmt
  DEFAULT_TIME_FORMAT = :RFC3339Nano

  def initialize(time_format: DEFAULT_TIME_FORMAT)
    @time_format = TimeFormats.const_get(time_format).new
  end

  def format(labels)
    labels.map { |label, value|
      value = @time_format.format(value) if label == :time
      value = value.to_s
      value = %("#{value}") if value =~ /\s/

      "#{label}=#{value}"
    }.join " "
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
