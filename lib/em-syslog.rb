
require 'socket'
require 'eventmachine'
require 'em-syslog/syslog.rb'
require 'em-syslog/connection_tcp.rb'
require 'em-syslog/connection_udp.rb'
require 'em-syslog/connection_unix.rb'
require 'em-syslog/logger.rb'

module EventMachine
  module Syslog
    ##
    # Candy for creating a new Logger object or returned a cached one

    def self.logger( *a)
      EventMachine::Logger.new( *a)
    end
  end
end

if __FILE__ == $0
  EM.run {
    EM.kqueue if EM.kqueue?
    EM.epoll if EM.epoll?

    logger = EM::Syslog.logger( {:idenity => "em-syslog-test" })
    EM.next_tick {
      logger.log( "TEST INFO", :daemons, :info)
      logger.mail_error( "MAIL ERROR")
    }
  }
end

require 'em-syslog/version.rb'

