# encoding: UTF-8
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


require "iconv"

if RUBY_VERSION < "1.9"
  $KCODE = 'UTF8'
  require 'jcode'
end

include Ucp::Pdu

class Ucp::Util::UCP
  # Hash from single character string to a byte value
  @gsmtable = {}
  # Hash from byte value to single character string
  @asciitable = {}
  # Hash from single character string to a byte value
  @extensiontable = {}
  # Hash from byte value to single character string
  @extensiontable_rev = {}

  # add a character mapping to the 7bit GSM default alphabet
  :private
  def self.add_char(value, char)
    @gsmtable[char] = value
    @asciitable[value] = char
  end

  # add an extension character to the 7bit GSM default alphabet
  :private
  def self.add_extchar(value, char)
    @extensiontable[char] = value
    @extensiontable_rev[value] = char
  end

  # build/initialize the GSM default alphabet mapping tables
  def self.initialize_ascii2ira
    
    ('A'..'Z').each { |c| add_char(c.ord, c) }
    ('a'..'z').each { |c| add_char(c.ord, c) }
    ('0'..'9').each { |c| add_char(c.ord, c) }

    add_char(0x00, "@")
    add_char(0x01, "£")
    add_char(0x02, "$")
    add_char(0x03, "¥")
    add_char(0x04, "è")
    add_char(0x05, "é")
    add_char(0x06, "ù")
    add_char(0x07, "ì")
    add_char(0x08, "ò")
    add_char(0x09, "Ç")
    add_char(0x0A, "\n")
    add_char(0x0B, "Ø")
    add_char(0x0C, "ø")
    add_char(0x0D, "\r")
    add_char(0x0E, "Å")
    add_char(0x0F, "å")

    add_char(0x10, "Δ")
    add_char(0x11, "_")
    add_char(0x12, "Φ")
    add_char(0x13, "Γ")
    add_char(0x14, "Λ")
    add_char(0x15, "Ω")
    add_char(0x16, "Π")
    add_char(0x17, "Ψ")
    add_char(0x18, "Σ")
    add_char(0x19, "Θ")
    add_char(0x1A, "Ξ")
    # 0x1B is escape sequence for extended characters
    add_char(0x1C, "Æ")
    add_char(0x1D, "æ")
    add_char(0x1E, "ß")
    add_char(0x1F, "É")

    add_char(0x20, " ")
    add_char(0x21, "!")
    add_char(0x22, '"')
    add_char(0x23, "#")
    add_char(0x24, "¤")
    add_char(0x25, "%")
    add_char(0x26, "&")
    add_char(0x27, "'")
    add_char(0x28, "(")
    add_char(0x29, ")")
    add_char(0x2A, "*")
    add_char(0x2B, "+")
    add_char(0x2C, ",")
    add_char(0x2D, "-")
    add_char(0x2E, ".")
    add_char(0x2F, "/")

    add_char(0x3A, ":")
    add_char(0x3B, ";")
    add_char(0x3C, "<")
    add_char(0x3D, "=")
    add_char(0x3E, ">")
    add_char(0x3F, "?")

    add_extchar(0x65, "€")
    add_extchar(0x14, "^")
    add_extchar(0x28, "{")
    add_extchar(0x29, "}")
    add_extchar(0x2F, "\\")
    add_extchar(0x3C, "[")
    add_extchar(0x3D, "~")
    add_extchar(0x3E, "]")
    add_extchar(0x40, "|")
  end

  # pack a given text string in 7bit GSM default alphabet
  # return it as an hexadecimal string
  def self.pack7bits(str)
    s = ""
    str.each_char  { |c|
      ext = ""
      gsmchar = @gsmtable[c]

      unless gsmchar
        if @extensiontable.has_key?(c)
          ext = "0011011" # 1B
          gsmchar = @extensiontable[c]
        else
          gsmchar = @gsmtable[" "]
        end
      end

      tmp = gsmchar.to_s(2)

      remainder = tmp.length % 7
      if remainder != 0
        nfillbits = 7 - remainder
        tmp = "0" * nfillbits + tmp
      end
      
      s = tmp + ext + s
    }

    remainder = s.length % 8
    if remainder != 0
      nfillbits = 8 - remainder
      s = "0" * nfillbits + s
    end

    i = s.length - 8
    hexstr = ""
    while i >= 0
      c = s[i,8]

      tmp = c.to_i(2).to_s(16).upcase
      if tmp.length == 1
        tmp= "0" + tmp
      end
      hexstr += tmp
      i -= 8
    end

    hexstr
  end

  # convert standard string to IRA encoded hexstring
  def self.ascii2ira(str, max_bytes = nil)
    tainted = false  # true if not able to convert a character
    s = ""
    idx = 0
    str.each_char { |c|
      gsmchar = @gsmtable[c]

      ext = ""
      unless gsmchar
        if @extensiontable.has_key?(c)
          ext = "1B"
          gsmchar = @extensiontable[c]
        else
          gsmchar = @gsmtable[" "]
          tainted = true
        end
      end

      tmp = int2hex(gsmchar)

      if max_bytes
        # if adding this character exceeds the max allowed nr of bytes, break
        if ((tmp + ext + s).length * 7.0 / 16).ceil > max_bytes
          break
        end
      end

      s += ext + tmp
      idx += (ext + tmp).length / 2
    }

    required_septets = s.length / 2
    GsmPackedMsg.new(s, UCP.utf8_substr(str, 0, idx - 1), idx, required_septets, tainted)
  end

  # a dirty UTF-8 substring implementation
  # returns a substring of an UTF-8 encoded string, given the string, start end end characters
  def self.utf8_substr(str, idxs, idxe = nil)
    s = ""
    i = 0
    idxe = str.jlength - 1 unless idxe
    str.each_char do |c|
      s += c if i >= idxs && i <= idxe
      i += 1
    end
    s
  end

  # given a text, automatically split it if necessary and encode each part text in (IRA5) GSM default alphabet
  # returns an array of IRA5 hexadecimal strings, one per part
  def self.multi_ascii2ira(str, max_bytes)
    msgparts = []
    idx = 0

    if str.jlength <= 160
      packedmsg = UCP.ascii2ira(UCP.utf8_substr(str, idx), 140)
      if packedmsg.chars == str.jlength
        msgparts << packedmsg
        return msgparts
      end
    end

    while true
      packedmsg = UCP.ascii2ira(UCP.utf8_substr(str, idx), max_bytes)
      msgparts << packedmsg
      if idx + packedmsg.chars < str.jlength
        idx += packedmsg.chars
      else
        break
      end
    end
    msgparts
  end

  # convert a given UTF-8 string to "UCS-2"
  # returns an object representing the UCS-2 packed message
  def self.str2ucs2(str, max_bytes = nil)
    hexstr = ""
    str = Iconv.iconv("utf-16be", "utf-8", str).first
    i = 0
    str.each_byte do |c|
      hexstr += UCP.int2hex(c)
      i += 1
      if max_bytes && i == max_bytes
        break
      end
    end

    Ucs2PackedMsg.new(hexstr, UCP.utf8_substr(str, 0, i - 1), i / 2, i)
  end

  # given a text, automatically split it if necessary and encode each part text in UCS-2
  # returns an array of UCS-2 hexadecimal strings, one per part
  def self.multi_ucs2(str, max_bytes)
    msgparts = []
    idx = 0

    if str.jlength <= 70
      packedmsg = UCP.str2ucs2(str, 140)
      if packedmsg.chars == str.jlength
        msgparts << packedmsg
        return msgparts
      end
    end

    while true
      packedmsg = UCP.str2ucs2(UCP.utf8_substr(str, idx), max_bytes)
      msgparts << packedmsg

      if idx + packedmsg.chars < str.jlength
        idx += packedmsg.chars
      else
        break
      end
    end
    msgparts
  end

  # automatically build the necessary UCP pdu's in order to encode a given submit message
  # returns an array of UCP51 pdu's
  # (for now, it does NOT select automatically the SM encoding; it forces/assumes 7bit GSM)
  def self.make_multi_ucps(originator, recipient, message, mr = 0)
    ucps = []

    gsm7bit_encodable = false

    if gsm7bit_encodable
      gsmparts = UCP.multi_ascii2ira(message, 134)
    else
      gsmparts = UCP.multi_ucs2(message, 134)
    end

    part_nr = 1
    gsmparts.each { |gsmpart|
      ucp = Ucp51Operation.new
      ucp.basic_submit(originator, recipient, nil)

      if gsmparts.length > 1
        # concatenated xser
        ucp.add_xser("01", "050003" + UCP.int2hex(mr) + UCP.int2hex(gsmparts.length) + UCP.int2hex(part_nr))
      end

      if gsm7bit_encodable
        ucp.set_fields({:mt => 3, :msg => gsmpart.encoded})
        # DCS xser
        ucp.add_xser("02", "01")
      else
        ucp.set_fields({:msg => gsmpart.encoded, :mt => 4, :nb => gsmpart.encoded.length * 4})
        # DCS xser
        ucp.add_xser("02", "08")
      end

      ucps << ucp
      part_nr += 1
    }
    ucps
  end

  # return an encoded originator alphanumeric address
  # to be used in the "oadc" field, if alphanumeric
  def self.packoadc(oa)
    packedoa = UCP.pack7bits(oa)

    # esta conta nao esta correcta... por causa das extensoes...
    #useful_nibbles=packedoa.length
    useful_nibbles = (oa.length * 7.0 / 4).ceil

    tmp = useful_nibbles.to_s(16).upcase
    if tmp.length == 1
      tmp = "0" + tmp
    end

    tmp + packedoa
  end

  # convert an hexadecimal string to a binary string
  def self.hextobin(hstr)
    bstr = ""
    i = 0
    while i < hstr.length
      tmp = hstr[i, 2].to_i(16).to_s(2)

      nfillbits = 8 - tmp.length
      if nfillbits != 0
        tmp = "0" * nfillbits + tmp
      end

      bstr += tmp
      i += 2
    end
    bstr
  end


  def self.hextobin_reversed(hstr)
    bstr = ""
    i = 0
    while i < hstr.length
      tmp=hstr[i, 2].to_i(16).to_s(2)

      nfillbits = 8 - tmp.length
      if nfillbits != 0
        tmp = "0" * nfillbits + tmp
      end

      bstr = tmp + bstr
      i += 2
    end
    bstr
  end

  # decode a 7bit packed GSM default alphabet hexstring
  def self.decode7bitgsm(str)        
    unencoded = ""
    bstr = UCP.hextobin_reversed(str)
    # 110 1111 110 1100 110 0001
    # 1000011 1011101 0110111   000

    i = bstr.length - 7
    while i >= 0
      value = bstr[i, 7].to_i(2)
      if value == 0x1B
        i -= 7
        value = @extensiontable_rev[bstr[i, 7].to_i(2)] || " "
        unencoded += value
      else
        val = @asciitable[value] || " "
        unencoded += val
      end
      i -= 7
    end

    unencoded
  end

  # decode an IRA5 hexadecimal represented string to string
  def self.decode_ira(str)
    unencoded = ""

    i = 0
    while i < str.length
      hexv = str[i, 2]
      if "1B" == hexv
        i += 2
        hexv = str[i, 2]
        unencoded += @extensiontable_rev[hexv.to_i(16)] || " "
      else
        unencoded += @asciitable[hexv.to_i(16)] || " "
      end

      i += 2
    end

    unencoded
  end

  # convert an integer to an hex string, two (or given) nibbles wide
  def self.int2hex(i, max_nibbles = 2)
    tmp = i.to_s(16).upcase
    if tmp.length % 2 != 0
      tmp = "0" + tmp
    end

    remaining_nibbles = max_nibbles - tmp.length
    if remaining_nibbles > 0
      tmp = "0" * remaining_nibbles + tmp
    end

    tmp
  end

  # given a UCP pdu string, return a UCP pdu object
  def self.parse_str(ustr)
    return nil unless ustr

    arr = ustr[(ustr.index(2.chr) + 1) .. -2].split("/")
    # trn = arr[0]
    # length = arr[1]
    operation_type = arr[2]
    operation = arr[3]

    msg_class = case operation_type
                  when "O"
                    operation_class(operation)
                  when "R"
                    result_class(operation)
                end
    msg_class ? msg_class.new(arr) : nil
  end

  # given an UCP pdu object, build a corresponding result pdu
  def self.make_ucp_result(ucp)
    return nil unless ucp

    result_cls = result_class(ucp.operation)
    if result_cls
      ucpmsg = result_cls.new
      ucpmsg.trn = ucp.trn
      ucpmsg
    else
      nil
    end
  end

  # convert hexadecimal represent string to string, assuming a byte per character
  def self.hex2str(hexstr)
    str = ""
    hexstr.scan(/../).each { |tuple| str += tuple.hex.chr }
    str
  end

  # given an UCP pdu object, decode message field
  def self.decode_ucp_msg(ucp)
    dcs = ucp.dcs.to_i(16)

    if (dcs & 0x0F == 0x01) || (dcs & 0x0F == 0x00)
      case ucp.operation
        when "01"
          UCP.decode_ira(ucp.get_field(:msg))
        when "30"
          UCP.decode_ira(ucp.get_field(:amsg))
        when "51", "52", "53"
          case ucp.get_field(:mt)
            when "2"
              # numeric message.. return it as it is
              ucp.get_field(:msg)
            when "3"
              UCP.decode_ira(ucp.get_field(:msg))
            else
            # unexpected "mt" value. return nil explicitely
              nil
          end
        else
          # unexpected operation. return nil explicitely
          nil
      end
    elsif (dcs & 0x0F == 0x08) || (dcs & 0x0F == 0x09)
      str = UCP.hex2str(ucp.get_field(:msg))
      Iconv.iconv("utf-8", "utf-16be", str).first
    else
      # cant decode text; unsupported DCS
      nil
    end
  end

  # given an UCP pdu object, decode the originator address
  def self.decode_ucp_oadc(ucp)
    otoa = nil
    oadc = ucp.get_field(:oadc)

    if ["51", "52", "53", "54", "55", "56", "57", "58"].include? ucp.operation
      otoa = ucp.get_field(:otoa)
    end

    if otoa == "5039"
      UCP.decode7bitgsm(oadc[2..-1])
    else
      oadc
    end
  end


  # initialize tables on first class reference, in fact when loading it
  initialize_ascii2ira

  private
  def self.operation_class(operation)
    case operation
      when "01"
        Ucp01Operation
      when "30"
        Ucp30Operation
      when "31"
        Ucp31Operation
      when "51"
        Ucp51Operation
      when "52"
        Ucp52Operation
      when "53"
        Ucp53Operation
      when "54"
        Ucp54Operation
      when "55"
        Ucp55Operation
      when "56"
        Ucp56Operation
      when "57"
        Ucp57Operation
      when "58"
        Ucp58Operation
      when "60"
        Ucp60Operation
      when "61"
        Ucp61Operation
    end
  end

  def self.result_class(operation)
    case operation
      when "01"
        Ucp01Result
      when "30"
        Ucp30Result
      when "31"
        Ucp31Result
      when "51"
        Ucp51Result
      when "52"
        Ucp52Result
      when "53"
        Ucp53Result
      when "54"
        Ucp54Result
      when "55"
        Ucp55Result
      when "56"
        Ucp56Result
      when "57"
        Ucp57Result
      when "58"
        Ucp58Result
      when "60"
        Ucp60Result
      when "61"
        Ucp61Result
    end
  end
end
