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

class Ucp::Pdu::Ucp30Result < Ucp::Pdu::UCPMessage

  def initialize(fields = nil)
    super("R", "30")
    return unless fields

    @trn = fields[0]
    if fields[4] == "A"
      # 10/00039/R/30/A//067345:070295121212/6F
      ack(fields[5], fields[6])
    elsif fields[4] == "N"
      # 11/00022/R/30/N/24//08
      nack(fields[5], fields[6])
    else
      raise "invalid result in UCP30"
    end
  end


  def ack(mvp = "", sm = "")
    @field_names=[:ack, :sm] # should this also include mvp - TODO check spec
    @field_values[:ack] = "A"
    @field_values[:mvp] = mvp
    @field_values[:sm] = sm
  end

  def nack(ec, sm = "")
    @field_names=[:nack, :ec, :sm]
    @field_values[:nack] = "N"
    @field_values[:ec] = ec
    @field_values[:sm] = sm
  end
end
