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

require 'socket'

class Ucp::Util::UcpServer

  def initialize(handler,port,host=nil)
    @server = host ? TCPServer.open(host, port) : TCPServer.open(port)
    @server.setsockopt( Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1 )


    port = @server.addr[1]
    addrs = @server.addr[2..-1].uniq

    puts "*** listening on #{addrs.collect{|a|"#{a}:#{port}"}.join(' ')}"

    Thread.start do
      loop do
        socket = @server.accept

        Thread.start do # one thread per client
          s = socket

          port = s.peeraddr[1]
          name = s.peeraddr[2]
          addr = s.peeraddr[3]

          #puts "*** receiving from #{name}:#{port}"

          begin
            while line = s.gets(3.chr) # read a line at a time

              #puts "#{addr} [#{Time.now}]: #{line}"

              puts "Srecv: #{line}\n"              
              ucp = UCP.parse_str(line)

              if ["01", "30", "51", "52"].include? ucp.operation
                text = UCP.decode_ucp_msg(ucp)
                #puts "texto_recebido: #{text}\n"
                account = "unknown"
                smsreq = SmsRequest.new(UCP.decode_ucp_oadc(ucp), ucp.get_field(:adc), text, account, addr, port)
                smsreq.set_parts_info(ucp.message_ref, ucp.part_nr, ucp.total_parts)
                handler.call(smsreq)
              elsif ucp.operation == "60"
                if @auth_handler
                  authreq = AuthRequest.new(ucp.get_field(:oadc), UCP.decode_ira(ucp.get_field(:pwd)), addr,port)
                  auth_result = @auth_handler.call(authreq)
                  unless auth_result
                    reply_ucp = UCP.make_ucp_result(ucp)
                    reply_ucp.nack("01", "authentication failed")
                    #puts "reply #{reply_ucp.to_s}"
                    s.print reply_ucp.to_s
                    puts "Ssent: #{reply_ucp.to_s}\n"
                    puts "*** #{name}:#{port} forced disconnected"
                    s.close # close socket
                    break
                  end
                end
              end

              reply_ucp = UCP.make_ucp_result(ucp)
              reply_ucp.ack("ok")

              #puts "reply #{reply_ucp.to_s}"
              s.print reply_ucp.to_s
              puts "Ssent: #{reply_ucp.to_s}\n"
            end
          ensure
            puts "*** #{name}:#{port} disconnected/closed"
            s.close # close socket on error
          end
        end
      end
    end
  end

  def stop
    @server.close
  end

  def set_authentication_handler(handler)
    @auth_handler = handler
  end

end
