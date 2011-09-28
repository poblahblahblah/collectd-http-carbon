require 'rubygems'
require 'amqp'
require 'sinatra'
require 'yajl'
Thread.abort_on_exception = true

class Worker < Sinatra::Application
  post '/post-collectd' do
    prefix      = "eharmony"
    amqp_queue  = "graphite"
    channel     = AMQP.channel
    exchange    = channel.topic(amqp_queue, :auto_delete => false, :durable => true)
    queue       = channel.queue(Socket.gethostname)
    json        = StringIO.new(request.body.read)
    parser      = Yajl::Parser.new
    data_array  = parser.parse(json)
    data_array.each do |d|
      i = 0
      hostname = d['host'].gsub('.', '_')
      plugin, plugin_instance, type, type_instance, time = d['plugin'], d['plugin_instance'], d['type'], d['type_instance'], d['time']
      plugin_string = plugin
      plugin_string = %W(#{plugin_string} #{plugin_instance}).join('-') if !plugin_instance.empty?
      type_string   = type
      type_string   = %W(#{type_string} #{type_instance}).join('-') if !type_instance.empty?
      # collectd wrote their own time standard, which is a 30 bit left shift.
      # for collectd 4.x we shouldn't do anything, since the time is unix epoch.
      # for collectd 5.x we need to do a 30bit right shift. joy.
      time = time >> 30 if time.to_s.length > 11
      d['dsnames'].each do |ds|
        routing_key   = [ prefix, hostname, plugin_string, type_string, ds ].join('.').gsub('.-', '.') 
        routing_key   = routing_key.squeeze('..').gsub('.value', '').gsub(' ', '_')
        values        = d['values'][i]
        data          = [ values, time ].join(' ')
        begin
          exchange.publish(data, :routing_key => routing_key)
        rescue => exception
          retry
        end
        i +=1
      end
    end
  end

  get '/' do
    "SYSTEM UP"
  end
end
