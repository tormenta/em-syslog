Gem::Specification.new do |s|
  s.name = %q{em-syslog}
  s.version = "0.0.1"

  s.authors << %q{Digital Akasha}
  s.date = %q{2012-12-12}
  s.email = %q{tormenta@digitalakasha.com}
  s.homepage = "http://www.digitalakasha.com/"

  s.files = [ "lib/em-syslog.rb" ]
  s.add_dependency('eventmachine', '>= 0.12.10')
  s.required_paths << %q{lib}
  s.summary = %q{Simple Logger Class For Eventmachine Applications}
end
