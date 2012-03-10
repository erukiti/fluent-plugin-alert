# coding: utf-8

class Fluent::AlertOutput < Fluent::Output
  class FormatterText
    def parse
    end
    def initialize(format)
      @output = ''
    end

    def node_var(varname, data)
      if data[varname].is_a? Hash
        buf = ''
        data[varname].each do |k, v|
          buf += "\n" if buf != ''
          buf += "#{k}: #{v}"
        end
        buf
      else
        data[varname]
      end
    end

  end


  Fluent::Plugin.register_output('alert', self)

  # config_param :hoge, :string, :default => 'hoge'

  def initialize
    super
    @alert_list = []
  end

#  def match_regexp(regexp, var)
#p Regexp.new(regexp) =~ var
#    Regexp.new(regexp) =~ var
#  end




  def configure(conf)
return
    p conf
    conf.elements.select { |e| e.name == 'alert'}.each do |e|
      p e
      p e.elements[0]
      p e.elements[1]
#    
    end
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
