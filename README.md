# SimpleLogger

Simple structured logger for Ruby.

Unopinionated but tries to ease ingestion and transformations through Loki's
[Promtail][promtail], mainly by way of a [Logfmt][logfmt] appender.

[logfmt]: https://brandur.org/logfmt
[promtail]: https://grafana.com/docs/loki/latest/clients/promtail/

## Usage:

Log to stderr with the (default) Logfmt format:

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
# time=2022-10-21T16:30:04.381572373+02:00

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

## More

See `Appenders` for alternative formats.
