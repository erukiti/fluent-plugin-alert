# coding: utf-8

class Fluent::AlertOutput < Fluent::Output
  class FormatterText
    attr_accessor :text

    def initialize(format)
      @text = ''
    end

    def output_var_string(var)
      text_list = var.split(/\n/)
      if text_list.size == 1
        @text += "\"#{var}\"\n"
      else
        if @text.rindex("\n")
          indent = @text.size - (@text.rindex("\n") + 1)
        else 
          indent = @text.size
        end
        indent += 1

        @text += "\"#{text_list[0]}\\n\n"
        (1 .. text_list.size - 2).each do |i|
          @text += ' ' * indent + "#{text_list[i]}\\n\n"
        end
        @text += ' ' * indent + "#{text_list[text_list.size - 1]}\"\n"
      end
    end

    def output_var(var, indent = 0)
      if var.is_a? String
        output_var_string(var)
      elsif var.is_a? Hash
        if @text.size > 0
          indent += 2
          @text += "\n"
        end

        var.each do |key, var2|
          @text += ' ' * indent + "#{key}: "
          output_var(var2, indent)
        end
      elsif var.is_a? Array
        if @text.size > 0
          indent += 2
          @text += "\n"
        end

        index = 0
        var.each do |var2|
          @text += ' ' * indent + "#{index}: "
          output_var(var2, indent)
          index += 1
        end
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
