require 'minitest/autorun'
require_relative 'simple_logger'
require 'stringio'

# Minitest test suite mainly copied from utils-ruby's Utils::Log
class SimpleLoggerTest < Minitest::Test
  def setup
    @io = StringIO.new

    appender = SimpleLogger::Appenders::LogfmtWithLevels.new(@io)
    @log = SimpleLogger.new appenders: [appender]
  end

  def test_message
    @log.debug "test"
    assert_equal <<~EOS, @io.string
      DEBUG test
    EOS
  end

  def test_sub
    @log.sub("foo").debug "test"
    assert_equal <<~EOS, @io.string
      DEBUG foo: test
    EOS
  end

  def test_sub_sub
    @log.sub("foo").sub("bar").debug "test"
    assert_equal <<~EOS, @io.string
      DEBUG foo: bar: test
    EOS
  end

  def test_sub_with_labels
    @log.sub("foo", bar: "baz").debug "test"
    assert_equal <<~EOS, @io.string
      DEBUG foo: test bar=baz
    EOS
  end

  def test_labels_overriding
    @log.sub(bar: "baz")[bar: "foo"].debug "test"
    assert_equal <<~EOS, @io.string
      DEBUG test bar=foo
    EOS
  end

  def test_label_overriding_with_prefix
    @log.sub("foo", bar: "baz", baz: "quux")[baz: "foo"].debug "test"
    assert_equal <<~EOS, @io.string
      DEBUG foo: test bar=baz baz=foo
    EOS
  end

  def test_measure
    @log.sub("foo").debug("test") { 1+1 }
    assert_equal <<~EOS, replace_times(@io.string)
      DEBUG foo: test...
      DEBUG foo: test elapsed=TIME0
    EOS
  end

  def test_log_within_measure
    @log.sub("foo").debug("test1") do
      @log.sub("bar").debug("test2")
    end
    assert_equal <<~EOS, replace_times(@io.string)
      DEBUG foo: test1...
      DEBUG bar: test2
      DEBUG foo: test1 elapsed=TIME0
    EOS
  end

  def test_block_result
    debug_block_run = 0

    @log.level = :info
    @log.debug "some debug"

    debug_block_res = @log.debug "some debug 2" do
      debug_block_run += 1
      :res
    end

    @log.info "some info"
    @log.sub("foo").debug "some debug 2"
    @log.sub("foo").info "some info 2"

    assert_equal <<~EOS, @io.string
      \ INFO some info
      \ INFO foo: some info 2
    EOS
    assert_equal 1, debug_block_run
    assert_equal :res, debug_block_res
  end

  private def replace_times(s)
    n = -1
    s.gsub(/( elapsed=)\S+/) { "#{$1}TIME%d" % [n += 1] }
  end
end
