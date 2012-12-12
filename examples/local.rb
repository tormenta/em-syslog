require 'rubygems'
require 'eventmachine'
require 'em-syslog'

EM.run {
  EM.kqueue if EM.kqueue?
  EM.epoll if EM.epoll?

  logger = EM::Syslog.logger( "em-syslog-test")
  EM.next_tick {
    logger.log( "TEST INFO", :daemons, :info)
    logger.mail_error( "MAIL ERROR")
  }
}
