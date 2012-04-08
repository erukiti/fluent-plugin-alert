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

  class AlertMatchTagRegexp
    def initialize(var)
      @regexp = Regexp.new(var)
    end

    def match(tag, time, record)
      (@regexp =~ tag) != nil
    end
  end

  class AlertMatchRegexp
    def initialize(var)
      key, pattern = var.split(/ /, 2)
      @regexp = Regexp.new(pattern)
      @keys = key.split(/\./)
    end

    def match(tag, time, record)
      var = record
      @keys.each do |key|
        return false unless var[key]
        var = var[key]
      end

      (@regexp =~ var) != nil
    end
  end

  class AlertMatchAll
    def match(tag, time, record)
      true
    end
  end


  class AlertMatchFactory
    def self.create(elements)
      count = 0
      matcher = nil
      elements.each do |key, var|
        case key
        when 'match_tag_regexp'
          count += 1
          matcher = AlertMatchTagRegexp.new(var)
        when 'match_regexp'
          count += 1
          matcher = AlertMatchRegexp.new(var)
        end
      end

      if count == 0
        return AlertMatchAll.new
      elsif count == 1
        return matcher
      else
        raise Fluent::ConfigError
      end
    end
  end

  class AlertBase
    def initialize(elements)
      @matcher = AlertMatchFactory.create(elements)
    end

    def match(tag, time, record)
      @matcher.match(tag, time, record)
    end
  end

  class AlertDrop < AlertBase

    def initialize(elements)
      super
    end
    def emit(tag, time, record)
      return unless match(tag, time, record)
    end
  end

  class AlertConfig < AlertBase

    def initialize(elements)
      super
    end

    def emit(tag, time, record)
      return unless match(tag, time, record)
    end
  end

  class AlertMail < AlertBase
    def initialize(elements)
      super
    end

    def emit(tag, time, record)
      return unless match(tag, time, record)
    end
  end

  class Alert
    def create(elements)
      raise Fluent::ConfigError, "no type" unless elements['type']
      # FIXME: リフレクション使った何かに書き直す
      case elements['type']
      when 'config'
        return AlertConfig.new(elements)
      when 'mail'
        return AlertMail.new(elements)
      when 'drop'
        return AlertDrop.new(elements)
      end
    end

    def initialize
      @alert_list = []
    end

    def configure(elements_list)
      @alert_list = []
      elements_list.each do |elements|
        @alert_list << create(elements)
      end
    end

    def emit(tag, time, record)
    end
  end

  Fluent::Plugin.register_output('alert', self)

  def initialize
    super
    @alert = Alert.new
  end


  def configure(conf)
    elements_list = []
    conf.elements.select { |e| e.name == 'alert'}.each do |e|
      elements_list << e
    end
    @alert.configure(elements_list)
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
    es.each do |time, record|
      @alert.emit(tag, time, record)
    end
    chain.next
  end
end
