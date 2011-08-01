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

class Ucp::Pdu::UcpOperation < Ucp::Pdu::UCPMessage
  # @param [String] operation The 2-digit UCP operation number.
  # @param [Array] field_names An array of symbols representing the valid field names for this type of operation.
  # @param [Array] fields An array of strings representing the values of the fields. The first
  def initialize(operation = "", field_names = nil, fields = nil)
    super()
    @operation_type = "O"
    @operation = operation
    @field_names = field_names if field_names
    if field_names && fields
      @field_names = field_names
      @trn = fields[0]
      @operation_type = fields[2]
      @operation = fields[3]
       for i in 4..(fields.length-1)
         @field_values[@field_names[i-4]] = fields[i]
       end
    end
  end
end
