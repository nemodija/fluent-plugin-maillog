require 'helper'

class MaillogOutputTest < Test::Unit::TestCase

  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    tag test.test
  ]
  # CONFIG = %[
  #   path #{TMP_DIR}/out_file_test
  #   compress gz
  #   utc
  # ]

  def create_driver(conf = CONFIG, tag = 'test')
    Fluent::Test::OutputTestDriver.new(Fluent::MaillogOutput, tag).configure(conf)
  end

  def test_emit
maillog = <<"EOS"
Nov  5 22:39:01 hostname postfix/smtpd[10802]: 7D4381EB80E5: client=192-168-0-1.xxx.xxxx.ne.jp[192.168.0.1], sasl_method=PLAIN, sasl_username=xxxxx@from.example.com
Nov  5 22:39:02 hostname postfix/cleanup[10807]: 7D4381EB80E5: message-id=<545A28A8.9070401@from.example.com>
Nov  5 22:39:03 hostname opendkim[386]: 7D4381EB80E5: DKIM-Signature field added (s=default, d=from.example.com)
Nov  5 22:39:04 hostname postfix/qmgr[540]: 7D4381EB80E5: from=<xxxxx@from.example.com>, size=662, nrcpt=2 (queue active)
Nov  5 22:39:05 hostname postfix/smtp[10808]: 7D4381EB80E5: to=<zzzzz@to.example.com>, relay=mail.to.example.com[192.168.0.100]:25, delay=1, delays=0.01/0.17/0.81/0.02, dsn=2.0.0, status=sent (250 ok:  Message 662556263 accepted)
Nov  5 22:39:06 hostname postfix/qmgr[540]: 7D4381EB80E5: removed
EOS
    Timecop.freeze(Time.parse("2016-03-20 00:26:00")) do
      d = create_driver
      d.run do
        maillog.each_line do |message|
          d.emit({'message' => message.chomp}, Time.parse("2012-01-01 00:00:00 UTC").to_i)
        end
      end
      assert_equal 1, d.emits.size
      d.emits.each do |emit|
        assert_equal 'test.test', emit[0]
        assert_equal Time.parse("2012-01-01 00:00:00 UTC").to_i, emit[1]
        assert_equal '7D4381EB80E5', emit[2]['qid']
        assert_equal '545A28A8.9070401@from.example.com', emit[2]['message_id']
        assert_equal 'xxxxx@from.example.com', emit[2]['from']
        assert_equal '662', emit[2]['size']
        assert_equal '2', emit[2]['nrcpt']
        assert_equal 'zzzzz@to.example.com', emit[2]['to']
        assert_equal 'mail.to.example.com[192.168.0.100]:25', emit[2]['relay']
        assert_equal '1', emit[2]['delay']
        assert_equal '0.01/0.17/0.81/0.02', emit[2]['delays']
        assert_equal '2.0.0', emit[2]['dsn']
        assert_equal 'sent', emit[2]['status']
        assert_equal '250 ok:  Message 662556263 accepted', emit[2]['message']
        assert_equal Time.parse("2015-11-05 22:39:05").to_i, emit[2]['time']
      end
    end
  end

  def test_clean_record_cache_check_time
    t = Fluent::MaillogOutput.new
    latest_clean_time = t.latest_clean_time
    t.records = {
      'qid-001' => { 'time' => Time.now.to_i - 100 },
      'qid-002' => { 'time' => Time.now.to_i - 90  }
    }
    sleep 1
    t.clean_record_cache(1, 100)
    assert_equal false, t.records.keys.include?('qid-001')
    assert_equal true,  t.records.keys.include?('qid-002')
    assert_equal true,  t.latest_clean_time > latest_clean_time
  end

  def test_clean_record_cache_check_less_than_time
    t = Fluent::MaillogOutput.new
    latest_clean_time = t.latest_clean_time
    t.records = {
      'qid-001' => { 'time' => Time.now.to_i - 100 },
      'qid-002' => { 'time' => Time.now.to_i - 90  }
    }
    sleep 1
    t.clean_record_cache(10, 100)
    assert_equal true, t.records.keys.include?('qid-001')
    assert_equal true, t.records.keys.include?('qid-002')
    assert_equal true, t.latest_clean_time == latest_clean_time
  end

  def test_write_cache_dump_file
    Dir.mktmpdir do |dir|
      t = Fluent::MaillogOutput.new
      records = {'7D4381EB80E5' => {'qid' => '7D4381EB80E5'}}
      t.write_cache_dump_file("#{dir}/ut_temp", records)
      assert_equal 1, Dir.glob("#{dir}/*").count
      assert_equal true, JSON.parse(File.read("#{dir}/ut_temp")) == records
    end
  end

  def test_write_cache_dump_file_with_path_nil
    Dir.mktmpdir do |dir|
      t = Fluent::MaillogOutput.new
      records = {'7D4381EB80E5' => {'qid' => '7D4381EB80E5'}}
      t.write_cache_dump_file(nil, records)
      assert_equal 0, Dir.glob("#{dir}/*").count
    end
  end

  def test_write_cache_dump_file_with_records_zero
    Dir.mktmpdir do |dir|
      t = Fluent::MaillogOutput.new
      records = {}
      t.write_cache_dump_file("#{dir}/ut_temp", records)
      assert_equal 0, Dir.glob("#{dir}/*").count
    end
  end

  def test_read_cache_dump_file
    t = Fluent::MaillogOutput.new
    f = Tempfile.new('ut_temp')
    records = {'7D4381EB80E5' => {'qid' => '7D4381EB80E5'}}
    File.write(f.path, records.to_json)
    actual = t.read_cache_dump_file(f.path)
    assert_equal false, FileTest.exists?(f.path)
    assert_equal true, actual == records
  end

  def test_read_cache_dump_file_with_path_nil
    t = Fluent::MaillogOutput.new
    actual = t.read_cache_dump_file(nil)
    assert_equal true, actual == {}
  end

  def test_read_cache_dump_file_with_file_not_exists
    Dir.mktmpdir do |dir|
      t = Fluent::MaillogOutput.new
      actual = t.read_cache_dump_file("#{dir}/ut_temp")
      assert_equal true, actual == {}
    end
  end

  def test_revised_time
    t = Fluent::MaillogOutput.new
    Timecop.freeze(Time.parse("2015-01-01 00:00:01")) do
      assert_equal Time.parse("2014-12-31 23:59:59"), t.revised_time("Dec 31 23:59:59")
      assert_equal Time.parse("2015-01-01 00:00:00"), t.revised_time("Jan  1 00:00:00")
      assert_equal Time.parse("2015-01-01 00:00:01"), t.revised_time("Jan  1 00:00:01")
      assert_equal Time.parse("2014-01-01 00:00:02"), t.revised_time("Jan  1 00:00:02")
      # disabled revise_time
      t.revise_time = false
      assert_equal Time.parse("2015-12-31 23:59:59"), t.revised_time("Dec 31 23:59:59")
      assert_equal Time.parse("2015-01-01 00:00:00"), t.revised_time("Jan  1 00:00:00")
      assert_equal Time.parse("2015-01-01 00:00:01"), t.revised_time("Jan  1 00:00:01")
      assert_equal Time.parse("2015-01-01 00:00:02"), t.revised_time("Jan  1 00:00:02")
    end
  end
end
