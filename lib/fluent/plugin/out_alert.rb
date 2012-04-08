# coding: utf-8

class Fluent::AlertOutput < Fluent::Output
  class SendMail
    @@default = {}
    @@is_debug = false
    def self.set_default(default_config)
      @@default = {}
      @@default[:server] = default_config['server']
      @@default[:port] = default_config['port']
      @@default[:domain] = default_config['domain']
      @@default[:from] = default_config['from']
      @@default[:to] = default_config['to']
      @@default[:subject] = default_config['subject']
      @@default[:user] = default_config['user']
      @@default[:password] = default_config['password']
      @@default[:authentication] = default_config['authentication']
      @@default[:enable_starttls_auto] = default_config['enable_starttls_auto']
    end

    def self.debug_mode(mode)
      @@is_debug = mode
    end

    def self.send(config, body)
      server = config['server'] || @@default[:server]
      port = config['port'] || @@default[:port]
      domain = config['domain'] || @@default[:domain]
      from = config['from'] || @@default[:from]
      to = config['to'] || @@default[:to]
      subject = config['subject'] || @@default[:subject]
      user = config['user'] || @@default[:user]
      password = config['password'] || @@default[:password]
      authentication = config['authentication'] || @@default[:authentication]
      enable_starttls_auto = config['enable_starttls_auto'] || @@default[:enable_starttls_auto]

      if @@is_debug
        p from
        p to
        p subject
        p server
        p port
        p domain
        p from
        p user if user
        p password if password
        p authentication if authentication
        p enable_starttls_auto if enable_starttls_auto
        p body
        return
      end

      charset = 'utf-8'

      smtp = Net::SMTP.new(server, port)
      smtp.enable_starttls if enable_starttls_auto
      smtp.start(domain, user, password, :plain) do |connection|
        connection.send_mail(<<EOS, from, to.split(/,/))
Date: #{Time::now.strftime("%a, %d %b %Y %X")}
To: #{to}
Subject: #{subject.force_encoding('binary')}
Mime-Version: 1.0
Content-Type: text/plain; charset=#{charset}

#{body.force_encoding('binary')}
EOS
      end
    end

#body.encoding('utf-8', :invalid => :replace, :undef => :replace).force_encoding('binary')
  
  end

  class FormatterText
    attr_accessor :text

    def command_parse(command)
      command_composite = []
      while command.size > 0
        index = command.index(/\{(@|[a-zA-Z_\-]+\s*)([a-zA-Z_\-]*)\}/)
        unless index
          command_composite << [:text, command] if command.size > 0
          break
        end

        if index > 0
          command_composite << [:text, command[0 ... index]]
        end

        case $1.strip
        when '@'
          command_composite << [:var, $2]
        when 'hr'
          command_composite << [:hr]
        when 'nl'
          command_composite << [:nl]
        when 'if'
          # FIXME: MatchData 使って書き直す
          command = $'
          var = $2
          index = command.index(/\{end\}/)
          if index
            command_composite << [:if, var, command_parse(command[0...index])]
          else
            command_composite << [:if, var, command_parse(command)]
          end
        when 'each'
          command = $'
          var = $2
          index = command.index(/\{end\}/)
          if index
            command_composite << [:each, var, command_parse(command[0...index])]
          else
            command_composite << [:each, var, command_parse(command)]
          end
        end
        command = $'
      end

      command_composite
    end

    def initialize(command)
      @text = ''
      @command = command_parse(command)
    end

    def inspect
      @command.inspect
    end

    def format_run(var, command_list)
      command_list.each do |command|
        case command[0]
        when :text
          @text += command[1]
        when :var
          output_var(var[command[1]])
        when :nl
          output_nl
        when :hr
          output_hr
        when :if
          format_run(var, command[2]) if var[command[1]]
        when :each
          var[command[1]].each do |v2|
            format_run(v2, command[2])
          end
        end
      end
    end

    def format(var)
      @text = ''
      format_run(var, @command)
      @text
    end

    def output_nl
      @text += "\n" if @text.size > 0 && @text[@text.size - 1] != "\n"
    end

    def output_hr
      @text += "\n" if @text.size > 0 && @text[@text.size - 1] != "\n"
      @text += "----\n"
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
        @text += "\"#{var}\""
      else
        indent = get_textindent + 1

        @text += "\"#{text_list[0]}\\n\n"
        (1 .. text_list.size - 2).each do |i|
          output_indent(indent)
          @text += "#{text_list[i]}\\n\n"
        end
        output_indent(indent)
        @text += "#{text_list[text_list.size - 1]}\""
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
          output_nl
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
          output_nl
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
      require 'net/smtp'

      @config = elements
      @formatter = FormatterText.new(elements['format']) if elements['format']
    end

    def emit(tag, time, record)
      return unless match(tag, time, record)
      SendMail.send(@config, @formatter.format(record))
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
      @alert_list.each do |am|
        am.emit(tag, time, record)
      end
    end
  end

  Fluent::Plugin.register_output('alert', self)

  def initialize
    super
    @alert = Alert.new
  end

  config_param :server, :string, :default => "localhost"
  config_param :port, :integer, :default => 25
  config_param :domain, :string, :default => nil
  config_param :from, :string, :default => nil
  config_param :to, :string, :default => nil
  config_param :subject, :string, :default => nil
  config_param :user, :string, :default => nil
  config_param :password, :string, :default => nil
  config_param :authentication, :string, :default => nil
  config_param :enable_starttls_auto, :bool, :default => false

  def configure(conf)
    elements_list = []
    conf.elements.select { |e| e.name == 'alert'}.each do |e|
      elements_list << e
    end
    @alert.configure(elements_list)
    SendMail.set_default(conf)
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
