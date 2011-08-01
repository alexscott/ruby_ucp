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

class Ucp::Pdu::Ucp01Operation  < Ucp::Pdu::UcpOperation

  # @param [Array] fields This has a wierd signature
  # The first element seems to be the transaction nr. The third field is the operation type.
  # The fourth, the operation. Then the next are values for adc, oadc, ac, mt an msg fields.
  # A better way to do this would be to use a hash from field to value - Much more rubyish
  def initialize(fields = nil)
    super("01", [:adc, :oadc, :ac, :mt, :msg], fields)
  end

 def basic_submit(originator, recipient, message, ucpfields = {})
    # UCP01 only supports IRA encoded SMS (7bit GSM alphabet chars, encoded in 8bits)
    msg = UCP.ascii2ira(message).encoded

    # UCP01 does NOT support alphanumeric oadc
    oadc = originator

    @field_values = {:oadc => oadc, :adc => recipient, :msg => msg, :mt => 3}
    @field_values.merge! ucpfields
  end
end
