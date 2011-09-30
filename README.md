# collectd-http-carbon

This acts as a bridge between collectd's write_http plugin
and an AMQP message queueing system (we use rabbitmq) or 
directly to carbon. JSON sent from collectd get POSTed to
this Sinatra app which mangles the data ready for consumption
by carbon.

This is inspired by:  
Joe Miller's perl [collectd-graphite](https://raw.github.com/joemiller/collectd-graphite)  
Jordan Sissel's node [collectd-to-graphite](https://github.com/loggly/collectd-to-graphite)  
Gregory Szorc's [collectd-carbon](https://github.com/indygreg/collectd-carbon)  

## Dependencies

native packages:  
  ruby-devel  

gems:  
  eventmachine --pre  
  amqp  
  sinatra  
  unicorn  

## Installation

bundle install

## Configuration

unicorn.conf:  
_ You will probably want to adjust the worker_processes to fit your own needs.  
- decide whether you are sending directly to carbon or to an AMQP cluster. Your mode options are "amqp" or "direct".  
- amqp_server will need to be entered if you want to use it in AMQP mode.  
- grahpite_server and graphite_port if you want to use it in direct mode.  

worker.rb:  
- prefix: we use eharmony, but I've seen "collectd" and "servers" in others' solutions.  
  Set this to whatever suits your needs.  
- amqp_exchange: name of your exchange if using amqp. By default carbon binds to "graphite".  

## Tuning

You may find that collectd or the unicorn servers are making
a lot of TCP connections which means you will end up with
a  lot of sockets being tied up in TCP_WAIT. On the collectd
clients this should not really be an issue, but as you scale
up you will definitely find this an issue on the servers
running this code. You can either get enable tcp_tw_recycle
via /proc/sys/net/ipv4/tcp_tw_recycle or the more proper way,
net.ipv4.tcp_tw_recycle in /etc/sysctl.conf. This will recycle
the TCP sockets almost immediately.

If you prefer you can also set net.ipv4.tcp_timestamps=1 and
net.ipv4.tcp_tw_reuse=1. Before you do any of these, please
check with your network administrator to verify that this won't
hose your network.

## To Do

- It has been suggested that there might be some benefit in using
(Rainbows!)[http://rainbows.rubyforge.org/] to handle all of the threading.
This would just add a simple config to the unicorn.conf file:  
    
    Rainbows! do
      use :ThreadSpawn
    end
    
- Pickle suppoort

## Support and Documentation

Aside from this brief documentation feel free to email me with
any questions, suggestions, concerns.

## License and Copyright

The MIT License

Copyright (c) 2011 eHarmony.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
