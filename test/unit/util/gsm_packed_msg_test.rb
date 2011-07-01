require "test/unit"
require "lib/ruby_ucp"

class GsmPackedMsgTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @msg = Ucp::Util::GsmPackedMsg.new("encoded","unencoded","chars","required_septets")
  end

  def test_to_s
    assert_equal "encoded", @msg.to_s
  end
end