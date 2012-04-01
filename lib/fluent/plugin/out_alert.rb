# coding: utf-8

class Fluent::AlertOutput < Fluent::Output
  class FormatterText
    attr_accessor :text

    def initialize(format)
      @text = ''
    end

    def output_indent(indent)
      @text += ' ' * indent
    end

	def get_textindent
      @text.rindex("\n") ? @text.size - (@text.rindex("\n") + 1) : @text.size
	end

    def output_var_string(var)
      text_list = var.split(/\n/)
      if text_list.size == 1
        @text += "\"#{var}\"\n"
      else
        indent = get_textindent + 1

        @text += "\"#{text_list[0]}\\n\n"
        (1 .. text_list.size - 2).each do |i|
          output_indent(indent)
          @text += "#{text_list[i]}\\n\n"
        end
        output_indent(indent)
        @text += "#{text_list[text_list.size - 1]}\"\n"
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
          output_indent(indent)
          @text += "#{key}: "
          output_var(var2, indent)
        end
      elsif var.is_a? Array
        if @text.size > 0
          indent += 2
          @text += "\n"
        end

        index = 0
        var.each do |var2|
          output_indent(indent)
          @text += "#{index}: "
          output_var(var2, indent)
          index += 1
        end
      end
    end
  end

  class AlertConfig
    def initialize(elements)
    end
  end

  class AlertMail
    def initialize(elements)
    end
  end

  class AlertFactory

    def self.create(elements)
      raise Fluent::ConfigError, "no type" unless elements['type']
      # FIXME: リフレクション使った何かに書き直す
      case elements['type']
      when 'config'
        return AlertConfig.new(elements)
      when 'mail'
        return AlertMail.new(elements)
      end
    end
  end

  Fluent::Plugin.register_output('alert', self)

  attr_reader :alert_list

  def initialize
    super
    @alert_list = []
  end

  def match_regexp(regexp, var)
    (Regexp.new(regexp) =~ var) != nil
  end

  def configure(conf)
    @alert_list = []
    conf.elements.select { |e| e.name == 'alert'}.each do |e|
      @alert_list << AlertFactory.create(e)
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
