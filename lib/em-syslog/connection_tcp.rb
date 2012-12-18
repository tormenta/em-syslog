
module EventMachine
  module Syslog
    ##
    # Our module to pass to EventMachine to create the connection handler

    module ConnectionTCP
      DEFAULTS = {:queue_max_size => 500,
                  :queue_batch_send => 20,
                  :on_hangup => nil,
                  :reconnect => true
                 }
      ##
      # setup our connection with remote/local information, with a hash config merged against ConnectionTCP::DEFAULTS

      def setup( host, port, config={})
        config = DEFAULTS.merge( config)
        @host = host
        @port = port
        @do_reconnect = config[:on_hangup]
        @reconnect = config[:reconnect]
        @queue = Array.new
        @connected = false
        true
      end

      ##
      # we got our connection, time to start sending any items we have queued up

      def post_init
        @connected = true
        queue_send_batch
      end

      ##
      # queue messages if we are not connected.

      def send_msg( msg)
        if @connected
          send_data( msg)
        else
          queue_push( msg)
        end
      end

      ##
      # Do you want to be told when it disconnects and/or do you want to reconnect right away config[:reconnect] = true 
      #  passing config[:on_hangup] provide a proc. 

      def unbind
        @connected = false
        reconnect( @host, @port) if @do_reconnect
        @on_hangup.call unless @on_hangup.nil?
      end

      private
      ##
      # Rotate out old messages for newer messages.

      def queue_push( msg)
        old_message = (@queue.length >= @queue_max_size) ? @queue.shift : nil
        @queue << msg
        old_message
      end

      ##
      # loop batch send on each tick sending at least config[:queue_batch_size] times

      def queue_send_batch
        run_list = @queue.slice!(0..@queue_batch_size)
        run_list.each {|msg|
          send_msg( msg)
        }
        unless @queue.empty?
          EM.next_tick {
            queue_send_batch
          }
        end
        true
      end
    end
  end
end 

