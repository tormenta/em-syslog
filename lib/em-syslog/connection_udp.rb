
module EventMachine
  module Syslog
    ##
    # Our module to pass to EventMachine to handle the UDP Connection over IP Socket

    module ConnectionUDP

      def setup( host, port)
        @host = host
        @port = port
      end

      ##
      # Should not be needed

      def notify_readable
        read_packet
      end

      ##
      # Should not be needed

      def read_packet
        data, sender = @unix_connection.recvfrom( 1024)
        true
      end

      ##
      # Handle no buffering just send it

      def send_msg( msg)
        send_datagram( msg, @host, @port)
      end
    end
  end
end 
