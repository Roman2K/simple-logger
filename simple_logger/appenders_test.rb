require 'minitest/autorun'
require_relative '../simple_logger'
require 'stringio'

class SimpleLogger

class AppendersTest < Minitest::Test
  def test_stdio
    assert_kind_of Appenders::WithMutex, Appenders.stdio($stderr)
    assert_kind_of Appenders::IO, Appenders.stdio(StringIO.new)
  end

  def test_Noop
    log = SimpleLogger.new(appender: Appenders::Noop.new)
    log.info "test"
  end

  def test_Logfmt
    io = StringIO.new
    log = SimpleLogger.new(
      appender: Appenders::Logfmt.new(Appenders.stdio(io))
    )

    log[foo: "bar"].info "test"
    assert_match %r{
      ^time=\S+\ level=info\ msg=test\ foo=bar$
    }x, io.string
  end

  def test_LogfmtHuman
    io = StringIO.new
    log = SimpleLogger.new(
      appender: Appenders::LogfmtHuman.new(Appenders.stdio(io))
    )

    log.info "test"
    assert_equal <<~EOS, io.string
      \ INFO test
    EOS

    io.reopen ""

    log[foo: "bar"].info "test"
    assert_equal <<~EOS, io.string
      \ INFO test foo=bar
    EOS

    io.reopen ""

    log[foo: "bar baz"].info "test"
    assert_equal <<~EOS, io.string
      \ INFO test foo="bar baz"
    EOS
  end

  def test_LogfmtHuman_duration
    io = StringIO.new
    log = SimpleLogger.new(
      appender: Appenders::LogfmtHuman.new(Appenders.stdio(io))
    )

    log[duration: 1.23, a_float: 1.23].debug "test"
    assert_equal <<~EOS, io.string
      DEBUG test duration=1.23s a_float=1.23
    EOS

    io.reopen ""

    log[duration: 0.999].debug "test"
    assert_equal <<~EOS, io.string
      DEBUG test duration=999ms
    EOS

    io.reopen ""

    log[duration: "a string"].debug "test"
    assert_equal <<~EOS, io.string
      DEBUG test duration="a string"
    EOS
  end
end

end
