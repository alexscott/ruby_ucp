require "test/unit"

class Ucp30OperationTest < Test::Unit::TestCase
  STX = 2.chr
  ETX = 3.chr

  def test_send_sms
    raw = "#{STX}00/00045/O/30/961234567/1234////////6F6C61/9E#{ETX}"
    ucp = Ucp30Operation.new
    ucp.basic_submit(1234, 961234567, "ola")
    assert_equal raw, ucp.to_s
  end
end