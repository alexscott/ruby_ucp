=begin
Ruby library implementation of EMI/UCP protocol v4.6 for SMS
Copyright (C) 2011, Sergio Freire <sergio.freire@gmail.com>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
=end


class Ucp::Pdu::Ucp30Operation  < Ucp::Pdu::UcpOperation
  def initialize(fields = nil)
    super("30", [:adc, :oadc, :ac, :nrq, :nad, :npid, :dd, :ddt, :vp, :amsg], fields)
  end

  def basic_submit(originator, recipient, message, ucpfields = {})
    # UCP30 only supports IRA encoded SMS (7bit GSM alphabet chars, encoded in 8bits)
    msg = UCP.ascii2ira(message).encoded

    # UCP30 does NOT support alphanumeric oadc
    oadc = originator

    @field_values = {:oadc => oadc, :adc => recipient, :amsg => msg}.merge ucpfields
  end

end
