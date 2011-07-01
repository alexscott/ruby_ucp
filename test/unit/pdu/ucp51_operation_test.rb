require "test/unit"

class Ucp51OperationTest < Test::Unit::TestCase
  STX = 2.chr
  ETX = 3.chr
  def setup
  end

  def test_send_sms
    raw = "#{STX}03/00107/O/51/01727654321/12345/55555/1/01720123445//0100////////////3//4432204D657373616765/////////////90#{ETX}"
    ucp = Ucp51Operation.new
    ucp.basic_submit("12345", "01727654321", "D2 Message")
    ucp.trn = "03"
    ucp.set_fields({:ac => "55555", :nrq => "1", :nadc => "01720123445", :npid => "0100", :mt => "3"})
    assert_equal raw, ucp.to_s
  end
end