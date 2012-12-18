em-syslog
=========
Easy to use interface for syslogging both for remote and local Linux/BSD systems.

Install
=========
* RubyGems.rog
> gem install em-syslog-logger

Upgrading 0.0.1 -> 0.0.2
=========
API Change
You most supply a config hash or nothing arugments on logger creation
Resource pattern has been updated see "Usage"
All other sugar is the same as before, but backend class struct changed around a bit.

Usage
=========
> DEFAULTS = {:idenity => $PROGRAM_NAME,
>             :include_hostname => false,
>             :resource => "udp:/dev/log"
>            }
* resource = tcp:(<abs_path>|//host|//host:port)|udp:(<abs_path>|//host|//host:port)
* include_hostname = some sysloggers seem to insert this just fine other will not

Example
=========
> EM.run {
>   logger = EM::Syslog.logger( {:idenity => "em-syslog-test"})
>   EM.next_tick {
>     logger.log( "TEST INFO", :daemons, :info)
>     logger.mail_error( "MAIL ERROR")
>   }
> }


License
=========
Copyright (c) 2012, Digital Akasha
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies, 
either expressed or implied, of Digital Akasha.
