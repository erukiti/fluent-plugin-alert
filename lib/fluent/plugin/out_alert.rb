# coding: utf-8

class Fluent::AlertOutput < Fluent::Output
  Fluent::Plugin.register_output('alert', self)

  # config_param :hoge, :string, :default => 'hoge'



  def init_buffering
    @buffer = {}
  end

  def initialize
    super
  end

  def configure(conf)
    super
  end

  def start
    super
  end

  def shutdown
    super
  end

  def format(tag, time, record)
    [tag, time, record].to_msgpack
  end

  def emit(tag, es, chain)
#    es.each do |time, record|
#      Fluent::Engine.emit(tag, time, record) if first_fire(time, record)
#    end
#    chain.next
  end
end
