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

module Ucp::Pdu

  class UCPMessage
    DELIMITER = "/"
    STX = 2.chr
    ETX = 3.chr

    attr_reader :operation, :operation_type, :dcs, :message_ref, :part_nr, :total_parts
    attr_accessor :trn

    # usado pelas classes que o extendem
    # @param [String] operation_type can be either "O" for operation, or "R" for result
    # @param [String] operation is one of the UCP defined operation numbers.
    def initialize(operation_type = "O", operation = "")
      @operation = operation
      @operation_type = operation_type
      @dcs = "01"

      @trn = "00"
      @field_names = []
      @field_values = Hash.new

      @message_ref = 0
      @part_nr = 1
      @total_parts = 1
    end

    def get_field(field)
      @field_values[field]
    end

    def set_field(field, value)
      @field_values[field] = value
    end

    def set_fields(ucpfields = {})
      @field_values = @field_values.merge ucpfields
    end


    def is_operation?
      @operation_type == "O"
    end

    def is_result?
      @operation_type == "R"
    end

    def is_ack?
      @field_values.has_key?(:ack)
    end

    def is_nack?
      @field_values.has_key?(:nack)
    end

    # The <checksum> is derived by the addition of all bytes of the header, data field separators
    # and data fields (i.e. all characters after the stx-character, up to and including the last “/”
    # before the checksum field). The 8 Least Significant Bits (LSB) of the result is then
    # represented as two printable characters.
    def checksum(s)
      sum = 0
      s.each_byte { |byte| sum += byte }
      sum.to_s(16)[-2, 2].upcase
    end

    def length(s)
      sprintf("%05d", s.length + 16)
    end

    # Converts the message to raw string ready for transmission.
    def to_s
      s = @field_names.map {|field| @field_values[field] ? @field_values[field].to_s : ""}.join(DELIMITER) + DELIMITER

      pdu = ["#{@trn}", length(s), @operation_type, @operation, s].join(DELIMITER)
      "#{STX}#{pdu}#{checksum(pdu)}#{ETX}"
    end
  end
end # module