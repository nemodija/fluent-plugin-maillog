# Fluent::Plugin::Maillog

Aggregate a maillog for Postfix.

## Installation

    gem build fluent-plugin-maillog.gemspec
    gem install fluent-plugin-maillog-0.0.1.gem

## Config

|param|description|type|required|default|
|---|---|---|---|---|
|tag|レコードに付与するtag|string|yes|nil|
|cache_dump_file|キャッシュ中のmaillogを停止時にダンプするファイル<br>指定がない場合はキャッシュデータはダンプしない|string|no|nil|
|clean_interval_time|キャッシュをcleanする間隔|integer|no|60 (sec)|
|lifetime|キャッシュ上の生存期間|integer|no|3600 (sec)|

## Usage

~~~
<source>
  type tail
  format /(?<message>.*)/
  path /var/log/maillog
  tag next
</source>

<match next>
  type maillog
  tag next.next
</match>

<match next.next>
  type stdout
</match>
~~~

## Development

    bundle install --path vendor/bundle

## Testing

    rake test
