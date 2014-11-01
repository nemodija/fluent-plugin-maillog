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

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::MaillogOutput, tag).configure(conf)
  end

  def test_emit
    d = create_driver
  end
end
