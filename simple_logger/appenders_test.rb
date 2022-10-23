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

  def test_pipe
    io = StringIO.new

    assert_respond_to Appenders.pipe(:IO, io), :append
    refute_respond_to Appenders.pipe(:IO, io), :pipe

    refute_respond_to Appenders.pipe(:Logfmt), :append
    assert_respond_to Appenders.pipe(:Logfmt), :pipe

    assert_respond_to Appenders.pipe(:Logfmt).pipe(:stderr), :append
    refute_respond_to Appenders.pipe(:Logfmt).pipe(:stderr), :pipe
  end

  def test_pipe_nesting
    io = StringIO.new

    appender_outer = Class.new(Appenders::Wrapper) do
      def append(entry)
        super entry.merge(from_outer: true)
      end
    end

    appender_inner = Class.new(Appenders::Wrapper) do
      def append(entry)
        super entry.merge(from_inner: true)
      end
    end

    Appenders.
      pipe(appender_outer).
      pipe(appender_inner).
      pipe(:Logfmt).
      pipe(:IO, io).
      append({msg: "hello"})

    assert_equal "msg=hello from_outer from_inner\n", io.string
  end
end

end
