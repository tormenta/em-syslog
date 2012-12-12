
require 'socket'
require 'eventmachine'

module EventMachine
  module Syslog
    # THIEVERY: http://github.com/kpumuk/ruby_syslog
    SEVERITIES = {
      :emergency => 0, # system is unusable
      :alert => 1, # action must be taken immediately
      :critical => 2, # critical conditions
      :error => 3, # error conditions
      :warning => 4, # warning conditions
      :notice => 5, # normal but significant condition
      :informational => 6, # informational messages
      :info => 6, # informational messages (short name for the previous)
      :debug => 7 # debug-level messages
    }
    # THIEVERY: http://github.com/kpumuk/ruby_syslog
    FACILITIES = {
      :kernel => 0, # kernel messages
      :user_level => 1, # user-level messages
      :mail => 2, # mail system
      :daemons => 3, # system daemons
      :security => 4, # security/authorization messages
      :internal => 5, # messages generated internally by syslogd
      :printer => 6, # line printer subsystem
      :network => 7, # network news subsystem
      :uucp => 8, # UUCP subsystem
      :clock => 9, # clock daemon
      :security1 => 10, # security/authorization messages
      :ftp => 11, # FTP daemon
      :ntp => 12, # NTP subsystem
      :log_audit => 13, # log audit
      :log_alert => 14, # log alert
      :clock1 => 15, # clock daemon
      :local0 => 16, # local use 0
      :local1 => 17, # local use 1
      :local2 => 18, # local use 2
      :local3 => 19, # local use 3
      :local4 => 20, # local use 4
      :local5 => 21, # local use 5
      :local6 => 22, # local use 6
      :local7 => 23 # local use 7
    }

    def self.logger( *a)
      EventMachine::Logger.new( *a)
    end

    module ConnectionUDP
      # EM does not support doing UDP over unix domain sockets, so we have to manually handle it.
      def self.create_unix
        ::Socket.new(
          ::Socket::PF_UNIX,
          ::Socket::SOCK_DGRAM
        )
      end

      def self.pack_unix( path)
        ::Socket.pack_sockaddr_un( path)
      end

      def setup( host, port, unix_connection=nil)
        @host = unix_connection.nil? ? host : ::Socket.pack_sockaddr_un( host)
        @port = port
        @unix_connection = unix_connection
        @unix_connection.connect( @host) unless @unix_connection.nil?
      end

      # Should not be needed
      def notify_readable
        read_packet
      end

      def read_packet
        data, sender = @unix_connection.recvfrom( 1024)
        true
      end

      def send_msg( msg)
        if @unix_connection.nil?
          send_datagram( msg, @host, @port)
        else
          @unix_connection.send( msg, 0)
        end
      end
    end

    module ConnectionTCP
      def setup( host, port)
        @host = host
        @port = port
        @queue = Array.new
        @connected = false
      end

      def post_init
        @connected = true
        @queue.size.times {
          send_msg( @queue.shift)
        }
      end

      def send_msg( msg)
        if @connected
          send_data( msg)
        else
          @queue.push( msg)
        end
      end

      def unbind
        @connected = false
        reconnect( @host, @port)
      end
    end
  end

  class Logger
    @@connection_cache = Hash.new
    attr_reader :idenity, :resource

    # Yup hack new class method for cache candy
    def self.new( idenity, resource="unix://dev/log")
      # See if we have a connection already in our cache      
      key = self.mk_cache_index_key( idenity, resource)
      return @@connection_cache[key] if @@connection_cache.has_key? key and @@connection_cache[key].error? == false

      # Otherwise allocate a new object to do the work
      instance = self.allocate
      instance.send( :initialize, idenity, resource)
      @@connection_cache[key] = instance
    end

    def initialize( idenity, resource)
      @idenity = idenity.to_s + "[" + Process.pid.to_s + "]"
      @resource = resource
      resource = self.class.parse_resource( resource)

      case resource[0]
      when :unix
        # need better checking here
        raise "unix domain socket #{resource[1]} does not exist!" unless ::File.exists?( resource[1])
        connection = Syslog::ConnectionUDP.create_unix
        resource << @connection
        @connection = EM.watch( @connection, Syslog::ConnectionUDP)
      when :tcp
        @connection = EM.connect( resource[1], resource[2], Syslog::ConnectionTCP)
      else
        @connection = EM.open_datagram_socket( '0.0.0.0', 0, Syslog::ConnectionUDP)
      end
      resource.shift
      @connection.setup( *resource)
    end

    def log( msg, severity, facility, debug=true)
      m = String.new
      if debug
        raise "Invalid log severity!" unless Syslog::SEVERITIES.has_key? severity
        raise "Invalid log facility!" unless Syslog::FACILITIES.has_key? facility
      end
      m += "<" + self.class.class_variable_get("@@syskey_#{facility}_#{severity}".to_sym) + ">"
      m += self.class.timestamp + " " + ::Socket.gethostname + " #{@idenity} " + msg.to_s
      @connection.send_msg( m)
    end

    #Meta program our facility/severity keys and methods
    Syslog::FACILITIES.each {|facility,facility_int|
      Syslog::SEVERITIES.each {|severity,severity_int|
        define_method( "#{facility}_#{severity}".to_sym) do |msg|
          log( msg, facility, severity, false)
        end
        Syslog.class_variable_set("@@syskey_#{facility}_#{severity}".to_sym, (facility_int * 8 + severity_int))
      }
    }

    private
    def self.timestamp( time=Time.now)
      day = time.strftime("%d")
      day = day.sub(/^0/, ' ') if day =~ /^0\d/
      time.strftime("%b #{day} %H:%M:%S")
    end

    # Likely not the fastest and best way to make a cache index
    def self.mk_cache_index_key( idenity, resource)
     idenity.to_s + resource.split(':').each {|i| i.gsub(/\./,'') }.join
    end

    def self.parse_resource( resource)
      split_point = resource.index(':')
      answer = [ resource[0..(split_point-1)].to_sym, resource[(split_point+1)..-1]]
      split_point = answer[1].index(':')
      if split_point.nil? == false and split_point > 0
        answer << answer[1][(split_point+1)..-1]
        answer[1] = answer[1][0..(split_point-1)]
      elsif split_point.nil? == false
        raise "Resource parse error"
      else
        answer[1].slice!(1..-1)
        answer << nil
      end
      answer
    end
  end
end 

if __FILE__ == $0
  EM.run {
    EM.kqueue if EM.kqueue?
    EM.epoll if EM.epoll?

    logger = EM::Syslog.logger( "em-syslog-test")
    EM.next_tick {
      logger.log( "TEST INFO", :daemons, :info)
      logger.mail_error( "MAIL ERROR")
    }
  }
end

