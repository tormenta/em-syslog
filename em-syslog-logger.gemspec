Gem::Specification.new do |s|
  s.name = %q{em-syslog-logger}
  s.version = "0.0.2"

  s.authors << %q{Digital Akasha}
  s.date = %q{2012-12-12}
  s.email = %q{tormenta@digitalakasha.com}
  s.homepage = "https://github.com/tormenta/em-syslog"

  s.files = [
    "lib/em-syslog/connection_tcp.rb",
    "lib/em-syslog/connection_udp.rb",
    "lib/em-syslog/connection_unix.rb",
    "lib/em-syslog/logger.rb",
    "lib/em-syslog/syslog.rb",
    "lib/em-syslog/version.rb",
    "lib/em-syslog.rb"
  ]
  s.add_dependency('eventmachine', '>= 0.12.10')
  s.require_paths << %q{lib}
  s.summary = %q{Simple Logger Class For Eventmachine Applications}
end
