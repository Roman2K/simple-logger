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

    io.rewind

    log[foo: "bar"].info "test"
    assert_equal <<~EOS, io.string
      \ INFO test foo=bar
    EOS

    io.rewind

    log[foo: "bar baz"].info "test"
    assert_equal <<~EOS, io.string
      \ INFO test foo="bar baz"
    EOS
  end
end

end
