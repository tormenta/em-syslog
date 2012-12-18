
module EventMachine
  module Syslog
    module ConnectionUDP
      ##
      # Our module to pass to EventMachine to handle the UDP Connection over IPC Socket

      module UNIX
        include ConnectionUDP
        ##
        # we also have to code around the difference of Socket.new in ruby 1.8 and 1.9

        def self.create_unix
          case RUBY_VERSION.split('.')[1].to_i
          when 8
            ::Socket.new(
              ::Socket::PF_UNIX,
              ::Socket::SOCK_DGRAM,
              0
            )
          else
            ::Socket.new(
              ::Socket::PF_UNIX,
              ::Socket::SOCK_DGRAM
            )
          end
        end

        def setup( ipc, path)
          ipc_address = ::Socket.pack_sockaddr_un( path)
          @unix_connection = ipc
          @unix_connection.connect( ipc_address)
        end

        def send_msg( msg)
          @unix_connection.send( msg, 0)
        end
      end
    end
  end
end
