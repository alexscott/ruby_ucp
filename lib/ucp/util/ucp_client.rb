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

require "socket"

include Ucp::Pdu
include Ucp::Util

class Ucp::Util::UcpClient

  def initialize(host, port, authcreds = nil)
    @host = host
    @port = port
    @connected = false
    @authcreds = authcreds
    @trn = 0
    @mr = 0
  end

  def connect
    begin
      @socket = TCPSocket.new(@host, @port)
      @connected = true
      @trn = 0
    rescue
      @connected = false
      return false
    end

    if @authcreds
      auth_ucp = Ucp60Operation.new
      auth_ucp.basic_auth(@authcreds[:login], @authcreds[:password])
      auth_ucp.trn = "00"
      answer = send_sync(auth_ucp)

      if good_answer(answer)
        next_trn
        return true
      else
        close
        return false
      end
    end
    # What happens when @authcreds is nil? Then we don't
  end

  def close
    begin
      @socket.close
    rescue
    end
    @connected = false
  end

  def connected?
    @connected = @socket && !@socket.closed? && @connected
  end

  def send_sync(ucp)
    unless connected?
      connect
      # se nao foi possivel ligar, retornar imediatamente com erro
      return nil unless connected?
    end

    begin
      @socket.print ucp.to_s
      puts "Csent: #{ucp}\n"
      answer = read_with_timeout(3.chr, nil)
      puts "Crecv: #{answer}\n"
    rescue
      puts "error: #{$!}"
      close
      return nil
    end

    # verificar o trn da resposta face a submissao
    replyucp = UCP.parse_str(answer)
    return nil unless replyucp

    if ucp.trn == replyucp.trn
      replyucp
    else
      puts "unexpected trn #{replyucp.trn}. Should be #{ucp.trn}"
      nil
    end
  end

  def send(ucp)
    unless connected?
      connect
      # se nao foi possivel ligar, retornar imediatamente com erro
      return false unless connected?
    end

    begin
      @socket.print ucp.to_s
    rescue
      puts "error: #{$!}"
      # deu erro, vamos fechar o socket
      close
      # error
      return false
    end

    # OK
    true
  end

  # Reads a message from the socket.
  # @param [Integer] timeout_in_seconds nil if no timeouts, otherwise we exit with a nil if the socket does not return any data after it times out.
  # @return [String] The raw string containing the UCP message
  # TODO Consider returning the raw message as a UCP message object.
  def read(timeout_in_seconds = nil)
    begin
      read_with_timeout(3.chr, timeout_in_seconds)
    rescue
      puts "error: #{$!}"
      # deu erro, vamos fechar o socket
      close
      nil
    end
  end

  def send_message(originator, recipient, message)
    ucps = UCP.make_multi_ucps(originator, recipient, message, next_mr)

    ucps.each do |ucp|
      ucp.trn = UCP.int2hex(next_trn)
      ans = send_sync(ucp)
      return false unless good_answer(ans)
    end

    true
  end


  def send_alert(recipient, pid)
    ucp = Ucp31Operation.new
    ucp.basic_alert(recipient, pid)

    ucp.trn = UCP.int2hex(next_trn)
    ans = send_sync(ucp)
    good_answer(ans)
  end

  def next_trn
    trn = @trn
    @trn += 1
    @trn = 0 if @trn > 99
    trn
  end

  def next_mr
    mr = @mr
    @mr += 1
    @mr = 0 if @mr > 255
    mr
  end

  private
  # @param [Ucp::Pdu::UCPMessage]
  # @return [Boolean] true if the answer message exists and is an ack.
  def good_answer(answer)
    answer && answer.is_ack?
  end

  def read_with_timeout(separator, timeout_in_seconds)
    if timeout_in_seconds
      return nil unless select([@socket], nil, nil, timeout_in_seconds)
    end
    @socket.gets(separator)
  end
end
