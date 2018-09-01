# Fluent::Plugin::Maillog

[![Build Status](https://secure.travis-ci.org/nemodija/fluent-plugin-maillog.png)](https://travis-ci.org/nemodija/fluent-plugin-maillog)
[![Coverage Status](https://coveralls.io/repos/github/nemodija/fluent-plugin-maillog/badge.svg?branch=master)](https://coveralls.io/github/nemodija/fluent-plugin-maillog)
[![Code Climate](https://codeclimate.com/github/nemodija/fluent-plugin-maillog/badges/gpa.svg)](https://codeclimate.com/github/nemodija/fluent-plugin-maillog)

Aggregate a maillog for Postfix.

## Installation

    gem build fluent-plugin-maillog.gemspec
    gem install fluent-plugin-maillog-0.9.0.gem

## Config

|param|description|type|required|default|
|---|---|---|---|---|
|tag|レコードに付与するtag|string|yes|nil|
|cache_dump_file|キャッシュ中のmaillogを停止時にダンプするファイル<br>指定がない場合はキャッシュデータはダンプしない|string|no|nil|
|clean_interval_time|キャッシュをcleanする間隔|integer|no|60 (sec)|
|lifetime|キャッシュ上の生存期間|integer|no|3600 (sec)|
|revise_time|現時刻より `time` が未来になる場合、日付を1年前に変更するかどうか<br>これは maillog に `year` が含まれないことへの対応|bool|no|true|
|field|参照する field を指定|string|no|message|

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
