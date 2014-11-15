require 'helper'

class MaillogOutputTest < Test::Unit::TestCase

  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
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
    d = create_driver
    d.run do
      maillog.each_line do |message|
        d.emit({'message' => message.chomp}, Time.parse("2012-01-01 00:00:00 UTC").to_i)
      end
    end
    assert_equal 1, d.emits.size
    d.emits.each do |emit|
      assert_equal 'test', emit[0]
      assert_equal Time.parse("2012-01-01 00:00:00 UTC").to_i, emit[1]
      assert_equal '7D4381EB80E5', emit[2]['qid']
      assert_equal '545A28A8.9070401@from.example.com', emit[2]['message_id']
      assert_equal 'default', emit[2]['dkim_s']
      assert_equal 'from.example.com', emit[2]['dkim_d']
      assert_equal 'zzzzz@to.example.com', emit[2]['to']
      assert_equal 'mail.to.example.com[192.168.0.100]:25', emit[2]['relay']
      assert_equal '1', emit[2]['delay']
      assert_equal '0.01/0.17/0.81/0.02', emit[2]['delays']
      assert_equal '2.0.0', emit[2]['dsn']
      assert_equal 'sent', emit[2]['status']
      assert_equal '250 ok:  Message 662556263 accepted', emit[2]['message']
      assert_equal Time.parse("Nov  5 22:39:05").to_i, emit[2]['time']
    end
  end

  def test_clean_records_check_time
    t = Fluent::MaillogOutput.new
    latest_clean_time = t.latest_clean_time
    t.records = {
      'qid-001' => { 'time' => Time.now.to_i - 100 },
      'qid-002' => { 'time' => Time.now.to_i - 90  }
    }
    sleep 1
    t.clean_records(1, 100)
    assert_equal false, t.records.keys.include?('qid-001')
    assert_equal true,  t.records.keys.include?('qid-002')
    assert_equal true,  t.latest_clean_time > latest_clean_time
  end

  def test_clean_records_check_less_than_time
    t = Fluent::MaillogOutput.new
    latest_clean_time = t.latest_clean_time
    t.records = {
      'qid-001' => { 'time' => Time.now.to_i - 100 },
      'qid-002' => { 'time' => Time.now.to_i - 90  }
    }
    sleep 1
    t.clean_records(10, 100)
    assert_equal true, t.records.keys.include?('qid-001')
    assert_equal true, t.records.keys.include?('qid-002')
    assert_equal true, t.latest_clean_time == latest_clean_time
  end

  def test_unremoved_records_write
    Dir.mktmpdir do |dir|
      t = Fluent::MaillogOutput.new
      records = {'7D4381EB80E5' => {'qid' => '7D4381EB80E5'}}
      t.unremoved_records_write("#{dir}/ut_temp", records)
      assert_equal 1, Dir.glob("#{dir}/*").count
      assert_equal true, JSON.parse(File.read("#{dir}/ut_temp")) == records
    end
  end

  def test_unremoved_records_write_with_path_nil
    Dir.mktmpdir do |dir|
      t = Fluent::MaillogOutput.new
      records = {'7D4381EB80E5' => {'qid' => '7D4381EB80E5'}}
      t.unremoved_records_write(nil, records)
      assert_equal 0, Dir.glob("#{dir}/*").count
    end
  end

  def test_unremoved_records_write_with_records_zero
    Dir.mktmpdir do |dir|
      t = Fluent::MaillogOutput.new
      records = {}
      t.unremoved_records_write("#{dir}/ut_temp", records)
      assert_equal 0, Dir.glob("#{dir}/*").count
    end
  end

  def test_unremoved_records_read
    t = Fluent::MaillogOutput.new
    f = Tempfile.new('ut_temp')
    records = {'7D4381EB80E5' => {'qid' => '7D4381EB80E5'}}
    File.write(f.path, records.to_json)
    actual = t.unremoved_records_read(f.path)
    assert_equal false, FileTest.exists?(f.path)
    assert_equal true, actual == records
  end

  def test_unremoved_records_read_with_path_nil
    t = Fluent::MaillogOutput.new
    actual = t.unremoved_records_read(nil)
    assert_equal true, actual == {}
  end

  def test_unremoved_records_read_with_file_not_exists
    Dir.mktmpdir do |dir|
      t = Fluent::MaillogOutput.new
      actual = t.unremoved_records_read("#{dir}/ut_temp")
      assert_equal true, actual == {}
    end
  end

  def test_reemit?
    t = Fluent::MaillogOutput.new
    assert_equal false, t.reemit?(nil, nil, nil)
    assert_equal true,  t.reemit?('Sat Nov 15 20:00:00 JST 2014', nil, nil)
    # start_send_time only
    assert_equal true,  t.reemit?('Sat Nov 15 20:00:00 JST 2014', 'Sat Nov 15 19:59:59 JST 2014', nil)
    assert_equal true,  t.reemit?('Sat Nov 15 20:00:00 JST 2014', 'Sat Nov 15 20:00:00 JST 2014', nil)
    assert_equal false, t.reemit?('Sat Nov 15 20:00:00 JST 2014', 'Sat Nov 15 20:00:01 JST 2014', nil)
    # end_send_time only
    assert_equal false, t.reemit?('Sat Nov 15 20:00:00 JST 2014', nil, 'Sat Nov 15 19:59:59 JST 2014')
    assert_equal true,  t.reemit?('Sat Nov 15 20:00:00 JST 2014', nil, 'Sat Nov 15 20:00:00 JST 2014')
    assert_equal true,  t.reemit?('Sat Nov 15 20:00:00 JST 2014', nil, 'Sat Nov 15 20:00:01 JST 2014')
    # start_send_time and end_send_time
    assert_equal true,  t.reemit?('Sat Nov 15 20:00:00 JST 2014', 'Sat Nov 15 19:59:59 JST 2014', 'Sat Nov 15 20:00:01 JST 2014')
    assert_equal true,  t.reemit?('Sat Nov 15 20:00:00 JST 2014', 'Sat Nov 15 20:00:00 JST 2014', 'Sat Nov 15 20:00:00 JST 2014')
    assert_equal false, t.reemit?('Sat Nov 15 20:00:00 JST 2014', 'Sat Nov 15 20:00:01 JST 2014', 'Sat Nov 15 19:59:59 JST 2014')
  end
end
