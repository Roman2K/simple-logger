require 'minitest/autorun'
require_relative '../simple_logger'
require 'time'

module SimpleLogger::Formatters

class LogfmtTest < Minitest::Test
  def setup
    @format = Logfmt.new(time_format: :RFC3339Nano)
  end

  private def format(labels) = @format.format(labels)

  def test_time_RFC3339Nano
    time = Time.parse "2022-10-22 08:22:42.790350102 +0200"

    assert_equal "time=2022-10-22T08:22:42.790350102+02:00", format({
      time: time,
    })

    assert_equal "other_time=2022-10-22T08:22:42.790350102+02:00", format({
      other_time: time,
    })
  end

  def test_empty_labels_hash
    assert_equal "", format({})
  end

  def test_floats
    assert_equal "elapsed=1.23456", format({elapsed: 1.23456})
  end

  def test_true
    assert_equal "some_bool other_bool=false", format({
      some_bool: true,
      other_bool: false,
    })
  end

  def test_quoting
    assert_equal %(name="Foo Bar"), format({name: "Foo Bar"})
    assert_equal %(name="Foo\\nBar"), format({name: "Foo\nBar"})
  end

  def test_escaping
    assert_equal %(name="\\"Foo\\nBar\\""), format({name: %("Foo\nBar")})
  end

  def test_label_quoting_or_escaping
    err = assert_raises RuntimeError do
      format({"foo bar" => "simple_value"})
    end

    assert_match(/invalid label: "foo bar"/, err.message)
  end
end

end
