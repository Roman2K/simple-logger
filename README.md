# SimpleLogger

Simple structured logger for Ruby.

Unopinionated but tries to ease ingestion and transformations through
[Loki][loki]'s [Promtail][promtail], mainly by way of a [Logfmt][logfmt]
appender.

[loki]: https://grafana.com/oss/loki/
[promtail]: https://grafana.com/docs/loki/latest/clients/promtail/
[logfmt]: https://brandur.org/logfmt

TODO:

* [x] Precise durations
  * [x] Formatted within LogfmtHuman only
* [x] Proper escaping of label names and values
* [x] Handle boolean labels
* [ ] Log exception backtraces (with chains of causes)
* [ ] Add FATAL level to both log and raise exceptions at once

## Usage

Log to stderr with the Logfmt format (default):

```ruby
log = SimpleLogger.new
log.info "hello"

# Output:
# time=2022-10-21T16:26:47.698336581+02:00 level=info msg=test
```

Only log messages of level INFO and above:

```ruby
log.level = :info

log.debug "this won't be printed"
```

Add labels for context:

```ruby
log[foo: "bar"].info "with some context"

# Output:
# time=2022-10-21T23:35:47.058038960+02:00 level=info msg="with some context" foo=bar

foo_log = log[name: "foo"]
foo_log[action: "printing"].info "with even more context"

# Output:
# time=2022-10-21T16:30:36.936114091+02:00 level=info msg="with even more context" name=foo action=printing
```

Add a prefix:

```ruby
bar_log = log["bar"]
bar_log[action: "printing"].info "with a prefix"

# Output:
# time=2022-10-21T16:31:46.761913456+02:00 level=info msg="bar: with a prefix" action=printing
```

## Exceptions

Log exception messages:

```ruby
begin
  raise "some err"
  some_action
rescue
  log[err: $!].error "failed to perform some action"
end

# Output:
# time=2022-10-21T19:00:17.875626710+02:00 level=error msg="failed to perform some action" err="RuntimeError (some err)"
```

Causes are printed as well:

```ruby
begin
  # ...nested raise/rescues...
rescue
  log[err: $!].error "some chain of exceptions"
end

# Output:
# time=2022-10-21T19:03:18.664221506+02:00 level=error msg="some chain of exceptions" err="RuntimeError (error while rescueing) < RuntimeError (original exception)"
```

Timed blocks:

```ruby
log.debug "sleeping" do
  sleep 0.5
end

# Output:
# time=2022-10-21T19:11:29.642238036+02:00 level=debug msg=sleeping...
# time=2022-10-21T19:11:30.142959299+02:00 level=debug msg=sleeping elapsed=0.50s
```

## Alternative formats

See `Appenders` for alternative formats.

Example using the human-friendly Logfmt-based appender:

```ruby
log = SimpleLogger.new(
  appender: SimpleLogger::Appenders::LogfmtHuman.new(
    SimpleLogger::Appenders.stderr,
  )
)

log.debug "greeting"
log[foo: "bar"].info "hello"
log.debug "greeted"

# Output:
# DEBUG greeting
#  INFO hello foo=bar
# DEBUG greeted
```
