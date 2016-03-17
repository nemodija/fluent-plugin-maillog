# Fluent::Plugin::Maillog

Aggregate a maillog for Postfix.

## Installation

    gem build fluent-plugin-maillog.gemspec
    gem install fluent-plugin-maillog-0.0.1.gem

## Config

|param|description|default|
|---|---|---|
|tag|整形後のタグ|*Required*|
|cache_dump_file|キャッシュ中のmaillogを停止時に出力するファイル|nil|
|clean_interval_time|キャッシュをcleanする間隔|60 (sec)|
|lifetime|キャッシュ上の生存期間|3600 (sec)|
|emit_start_time|emit期間の指定(開始)|nil|
|emit_end_time|emit期間の指定(終了)|nil|

## Usage

~~~
<source>
  type tail
  format /(?<message>.*)/
  path /var/log/maillog
  pos_file /usr/local/fluentd/run/maillog.pos
  tag next
</source>

<match next>
  type maillog
  tag next.next
</match>

<match next.next>
  stdout
</match>
~~~

## Development

    bundle install --path vendor/bundle

## Testing

    rake test
