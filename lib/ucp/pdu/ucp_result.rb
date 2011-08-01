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


class Ucp::Pdu::UcpResult < Ucp::Pdu::UCPMessage
  def initialize(operation, fields = nil)
    super()
    @operation_type="R"
    @operation = operation
    if fields
      @trn = fields[0]
      case fields[4]
        when "A"
        # 00/00019/R/61/A//6E
        ack(fields[5])
      when "N"
        # 00/00022/R/61/N/02//06
        nack(fields[5], fields[6])
      else
        raise "invalid result in UCP#{operation}"
      end
    end
  end

  # Make the result an acknowledgement
  def ack(sm = "")
    @field_names = [:ack, :sm]
    @field_values = {:ack => "A", :sm => sm}
  end

  # Make the result an error
  def nack(error_code, sm = "")
    @field_names = [:nack, :ec, :sm]
    @field_values = {:nack => "N", :ec => error_code, :sm => sm}
  end
end
