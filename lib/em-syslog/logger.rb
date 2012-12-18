
module EventMachine
  ##
  # Generic Logger Class, providing simple to use statements
  # auto fills in the most likely config DEFAULTS

  class Logger
    @@connection_cache = Hash.new
    begin
      @@hostname = ::Socket.gethostname.split('.')[0]
    rescue Exception
      @@hostname = 'localhost'
    end
    attr_reader :idenity, :resource, :include_hostname
    DEFAULTS = {:idenity => $PROGRAM_NAME,
                :include_hostname => false,
                :resource => "udp:/dev/log"
               }
    ##
    # hack new class method for caching connections, making it safe to keep variables out of scope.

    def self.new( config = {})
      config = DEFAULTS.merge config
      # See if we have a connection already in our cache      
      key = self.mk_cache_index_key( config[:idenity], config[:resource])
      return @@connection_cache[key] if @@connection_cache.has_key? key and @@connection_cache[key].error? == false

      # Otherwise allocate a new object to do the work
      instance = self.allocate
      instance.send( :initialize, config)
      @@connection_cache[key] = instance
    end

    ##
    # save out needed information from config, and start up the connection
    TYPE = 0
    HOST = 1
    IPC = 1
    PORT = 2

    def initialize( config)
      @idenity = config[:idenity].to_s + "[" + Process.pid.to_s + "]"
      @resource = config[:resource].dup
      @include_hostname = config[:include_hostname]
      resource = self.class.parse_resource( config[:resource])

      @connection = nil
      if resource[TYPE] == :tcp
        # resource[PORT] should return nil considering we only define a pair (resource_type|path)
        @connection = EM.connect( resource[HOST], resource[PORT], Syslog::ConnectionTCP)
        raise "unable to create connection" if @connection.nil?
        @connection.setup( resource[HOST], resource[PORT])
      elsif resource.length == 3
        @connection = EM.open_datagram_socket( '0.0.0.0', 0, Syslog::ConnectionUDP)
        raise "unable to create connection" if @connection.nil?
        @connection.setup( resource[HOST], resource[PORT])
      else
        # need better checking here
        raise "unix domain socket #{resource[IPC]} does not exist!" unless ::File.exists?( resource[IPC])
        c = Syslog::ConnectionUDP::UNIX.create_unix
        @connection = EM.watch( c, Syslog::ConnectionUDP::UNIX)
        raise "unable to create connection" if @connection.nil?
        @connection.setup( c, resource[IPC]) 
      end
    end

    ##
    # When called directly we need to make sure we were given valid facilities and severity

    def log( msg, facility, severity)
      raise "Invalid log severity!" unless Syslog::SEVERITIES.has_key? severity
      raise "Invalid log facility!" unless Syslog::FACILITIES.has_key? facility
      send_log( msg, facility, severity)
    end

    ##
    #Meta program our facility/severity keys and methods

    Syslog::FACILITIES.each {|facility,facility_int|
      Syslog::SEVERITIES.each {|severity,severity_int|
        define_method( "#{facility}_#{severity}".to_sym) do |msg|
          send_log( msg, facility, severity)
        end
        class_variable_set("@@syskey_#{facility}_#{severity}".to_sym, (facility_int * 8 + severity_int))
      }
    }
    Syslog::SEVERITIES.each {|severity,severity_int|
      define_method( severity) do |msg,facility|
        send_log( msg, ((facility.nil?) ? :daemons : facility), severity)
      end
    }

    ##
    # you must fix up the timestamp so that a space is injected in place of a leading 0
    # - returns "Dec  6 12:12:12"

    def self.timestamp( time=Time.now)
      day = time.strftime("%d")
      day = day.sub(/^0/, ' ') if day =~ /^0\d/
      time.strftime("%b #{day} %H:%M:%S")
    end

    private
    ##
    # Format and send message to syslog

    def send_log( msg, facility, severity)
      m = String.new
      m += "<" + self.class.send( :class_variable_get, "@@syskey_#{facility}_#{severity}".to_sym).to_s + ">"
      m += self.class.timestamp + " "
      m += @@hostname + " " if include_hostname
      m += "#{@idenity}: " + msg.to_s
      @connection.send_msg( m)
    end

    ##
    # Likely not the fastest and best way to make a cache index
    # - returns "#{idenitiy}#{ip|hostname|path.without_dots}"

    def self.mk_cache_index_key( idenity, resource)
     idenity.to_s + resource.split(':').each {|i| i.gsub(/\./,'') }.join
    end

    ##
    # Likely not the fastest and best way to parse the syslog resource idenity.
    # unix will always return a set length of 2 and host/port at length 3
    # - returns [ resource_type (:tcp|:udp), ipc_path|ip_address|hostname [, port]]
    
    def self.parse_resource( resource)
      split_point = resource.index(':')
      resource_type = resource[0..(split_point-1)].to_sym
      resource = resource[(split_point+1)..-1]
      if resource_type != :tcp and resource_type != :udp
        raise "Invalid resource syntax, protocol must be :tcp|:udp"
      elsif resource[0..1] == "//"
        resource_parts = resource.split('/')
        target_parts = resource_parts[2].split(':')
        raise "Invalid resource syntax: #{resource}" if target_parts.length > 2 or resource_parts.length > 3
        target_parts << 514 if target_parts.length == 1
        target_parts.unshift resource_type
      elsif resource[0,1] == "/"
        target_parts = [ resource_type, resource]
      else
        raise "Invalid resource syntax: can't detect connection type #{resource}"
      end
      target_parts
    end
  end
end 

