# coding: utf-8
require 'helper.rb'

class FormatterTextTest < Test::Unit::TestCase
  def test_output_var
    ## 文字列
    # 文字列単品
    f = Fluent::AlertOutput::FormatterText.new ""
    f.output_var "hoge"
    assert_equal "\"hoge\"", f.text

    # 複数行文字列
    f.text = ""
    f.output_var "multiline\nstring"
    assert_equal "\"multiline\\n\n string\"", f.text

    # 複数行文字列(3行)
    f.text = ""
    f.output_var "multiline\n3lines\nstring"
    assert_equal "\"multiline\\n\n 3lines\\n\n string\"", f.text

    # 継続状態、文字列単品"
    f.text = "hoge.html:80: "
    f.output_var "hoge"
	assert_equal "hoge.html:80: \"hoge\"", f.text

    # 継続状態、複数行文字列
    f.text = "hoge.html:80: "
    f.output_var "multiline\nstring"
	assert_equal "hoge.html:80: \"multiline\\n\n               string\"", f.text

    # 継続状態(\n含む)、文字列単品
    f.text = "hoge\nfuga: "
    f.output_var "piyo"
    assert_equal "hoge\nfuga: \"piyo\"", f.text

    # 継続状態(\n含む)、複数行文字列
    f.text = "hogehoge\nfuga: "
    f.output_var "multiline\nstring"
    assert_equal "hogehoge\nfuga: \"multiline\\n\n       string\"", f.text

	## 自分がHash/Array, 子が文字列
    # Hash, 文字列単品
    f.text = ""
    f.output_var("hoge" => "ほげ")
    assert_equal "hoge: \"ほげ\"", f.text

    # Hash, 複数行文字列
    f.text = ""
    f.output_var("hoge" => "multiline\nstring")
    assert_equal "hoge: \"multiline\\n\n       string\"", f.text

    # Hash複数, 文字列単品＆複数行文字列
    f.text = ""
    f.output_var("hoge" => "ほげ", "fuga" => "multiline\nstring")
    assert_equal "hoge: \"ほげ\"\nfuga: \"multiline\\n\n       string\"", f.text

    # 継続状態、Hash複数, 文字列単品＆複数行文字列
    f.text = "hoge.html:80: "
    f.output_var("hoge" => "ほげ", "fuga" => "multiline\nstring")
    assert_equal "hoge.html:80: \n  hoge: \"ほげ\"\n  fuga: \"multiline\\n\n         string\"", f.text

    # Array, 文字列単品
    f.text = ""
    f.output_var(["ほげ", "ふが"])
    assert_equal "0: \"ほげ\"\n1: \"ふが\"", f.text

    # Array, 複数行文字列
    f.text = ""
    f.output_var(["ほげ", "multiline\nstring"])
    assert_equal "0: \"ほげ\"\n1: \"multiline\\n\n    string\"", f.text

    ## 自分がHash/Array, 子がHash/Array
    # 非継続状態 Hash/Hash
    f.text = ""
    f.output_var({"hoge" => {"fuga" => "piyo"}})
    assert_equal "hoge: \n  fuga: \"piyo\"", f.text

    #継続状態 Hash/Hash
    f.text = "tpl/hoge.html:80: "
    f.output_var({"hoge" => {"fuga" => "piyo"}})
    assert_equal "tpl/hoge.html:80: \n  hoge: \n    fuga: \"piyo\"", f.text

    # 非継続状態 Hash/Hash
    f.text = ""
    f.output_var({"hoge" => ['piyo']})
    assert_equal "hoge: \n  0: \"piyo\"", f.text

    #継続状態 Hash/Hash
    f.text = "tpl/hoge.html:80: "
    f.output_var({"hoge" => ['piyo']})
    assert_equal "tpl/hoge.html:80: \n  hoge: \n    0: \"piyo\"", f.text
  end

  def test_output_nl
    f = Fluent::AlertOutput::FormatterText.new ""

    f.text = ""
    f.output_nl
    assert_equal "", f.text

    f.text = "\n"
    f.output_nl
    assert_equal "\n", f.text

    f.text = "hoge"
    f.output_nl
    assert_equal "hoge\n", f.text

    f.text = "hoge\nhoge"
    f.output_nl
    assert_equal "hoge\nhoge\n", f.text
  end

  def test_command_parse()
    f = Fluent::AlertOutput::FormatterText.new ""

    assert_equal [[:text, 'hoge']], f.command_parse("hoge")
    assert_equal [[:var, 'hoge']], f.command_parse("{@hoge}")
    assert_equal [[:var, 'fuga']], f.command_parse("{@fuga}")
    assert_equal [[:text, 'hoge'], [:var, 'hoge']], f.command_parse("hoge{@hoge}")
    assert_equal [[:text, 'hoge'], [:var, 'hoge'], [:text, 'fuga']], f.command_parse("hoge{@hoge}fuga")
    assert_equal [[:text, 'hoge'], [:var, 'hoge'], [:text, 'fuga'], [:var, 'piyo']], f.command_parse("hoge{@hoge}fuga{@piyo}")
    assert_equal [[:var, 'hoge'], [:var, 'fuga']], f.command_parse("{@hoge}{@fuga}")
    assert_equal [[:nl], [:hr]], f.command_parse("{nl}{hr}")
    assert_equal [[:if, 'hoge', [[:text, 'fuga']]]], f.command_parse("{if hoge}fuga{end}")
    assert_equal [[:text, ' '], [:if, 'hoge', [[:text, 'fuga']]]], f.command_parse(" {if hoge}fuga{end}")
    assert_equal [[:if, 'hoge', [[:text, 'fuga'], [:var, 'piyo']]]], f.command_parse("{if hoge}fuga{@piyo}{end}")
    assert_equal [[:if, 'hoge', [[:text, 'fuga']]], [:each, 'hoge', [[:text, 'fuga']]]], f.command_parse("{if hoge}fuga{end}{each hoge}fuga{end}")
  end

  def test_format
    f = Fluent::AlertOutput::FormatterText.new "hoge"
    assert_equal "hoge", f.format({})

    f = Fluent::AlertOutput::FormatterText.new "{@hoge}"
    assert_equal "\"fuga\"", f.format({'hoge' => 'fuga'})
    assert_equal "\"multiline\\n\n string\"", f.format({'hoge' => "multiline\nstring"})
    assert_equal "hoge: \n  fuga: \"piyo\"", f.format({"hoge" => {"hoge" => {"fuga" => "piyo"}}})

    f = Fluent::AlertOutput::FormatterText.new "hoge.html:80: {@hoge}"
    assert_equal "hoge.html:80: \n  hoge: \"ほげ\"\n  fuga: \"multiline\\n\n         string\"", f.format("hoge" => {"hoge" => "ほげ", "fuga" => "multiline\nstring"})

    f = Fluent::AlertOutput::FormatterText.new "{@hoge}{nl}"
    assert_equal "\"fuga\"\n", f.format({'hoge' => 'fuga'})
    assert_equal "\"multiline\\n\n string\"\n", f.format({'hoge' => "multiline\nstring"})
    assert_equal "hoge: \n  fuga: \"piyo\"\n", f.format({"hoge" => {"hoge" => {"fuga" => "piyo"}}})

    f = Fluent::AlertOutput::FormatterText.new "{@hoge}{hr}{@hoge}"
    assert_equal "\"fuga\"\n----\n\"fuga\"", f.format({'hoge' => 'fuga'})

    f = Fluent::AlertOutput::FormatterText.new "{if hoge}{@hoge}{end}"
    assert_equal "\"fuga\"", f.format({'hoge' => 'fuga'})
    assert_equal "", f.format({'fuga' => 'fuga'})

    f = Fluent::AlertOutput::FormatterText.new "{each hoge}{@fuga}{nl}{end}"
    assert_equal "\"piyo\"\n\"poyo\"\n", f.format({'hoge' => [{'fuga' => 'piyo'}, {'fuga' => 'poyo'}]})


  end

end

class AlertMatcherAllMatchTagRegexp < Test::Unit::TestCase
  def test_create
    matcher = Fluent::AlertOutput::AlertMatchFactory.create({'match_tag_regexp' => '\.config$'})
    assert_equal Fluent::AlertOutput::AlertMatchTagRegexp, matcher.class
  end

  def test_match
    matcher = Fluent::AlertOutput::AlertMatchFactory.create({'match_tag_regexp' => '\.config$'})
    assert_equal true, matcher.match("hoge.config", Time.now(), {})
    assert_equal false, matcher.match("hoge.configure", Time.now(), {})
  end
end

class AlertMatcherAllMatchTagRegexp < Test::Unit::TestCase
  def test_create
    matcher = Fluent::AlertOutput::AlertMatchFactory.create({'match_regexp' => 'hoge \/hoge$'})
    assert_equal Fluent::AlertOutput::AlertMatchRegexp, matcher.class
  end

  def test_match
    matcher = Fluent::AlertOutput::AlertMatchFactory.create({'match_regexp' => 'hoge \/hoge$'})
    assert_equal true, matcher.match("test.test", Time.now(), {'hoge' => '/hoge'})
    assert_equal false, matcher.match("test.test", Time.now(), {'fuga' => '/hoge'})
    assert_equal false, matcher.match("test.test", Time.now(), {'hoge' => 'hoge'})

    matcher = Fluent::AlertOutput::AlertMatchFactory.create({'match_regexp' => 'hoge.fuga \/hoge$'})
    assert_equal true, matcher.match("test.test", Time.now(), {'hoge' => {'fuga' => '/hoge'}})

  end
end

class AlertMatcherAllTest < Test::Unit::TestCase
  def test_create
    matcher = Fluent::AlertOutput::AlertMatchFactory.create({})
    assert_equal Fluent::AlertOutput::AlertMatchAll, matcher.class
  end

  def test_match
    matcher = Fluent::AlertOutput::AlertMatchFactory.create({})
    assert_equal true, matcher.match("hoge.fuga", Time.now(), {})
  end
end

class AlertTest < Test::Unit::TestCase
  def test_create
    alert = Fluent::AlertOutput::Alert.new

    assert_raise(Fluent::ConfigError, "no type") {
      alert.create({})
    }

    alert_module = alert.create('type' => 'config')
    assert_equal Fluent::AlertOutput::AlertConfig, alert_module.class

    alert_module = alert.create('type' => 'mail')
    assert_equal Fluent::AlertOutput::AlertMail, alert_module.class

    alert_module = alert.create('type' => 'drop')
    assert_equal Fluent::AlertOutput::AlertDrop, alert_module.class

    # alert_module で match までうまくいくか結合
    alert_module = alert.create('type' => 'drop', 'match_tag_regexp' => '\.hoge$')
    assert_equal true, alert_module.match('hoge.hoge', Time.now, {})
    alert_module = alert.create('type' => 'drop', 'match_tag_regexp' => '\.hoge$')
    assert_equal false, alert_module.match('hoge.fuga', Time.now, {})

    alert_module = alert.create('type' => 'drop', 'match_regexp' => 'hoge.fuga \/hoge$')
    assert_equal true, alert_module.match('piyo.piyo', Time.now, {'hoge'=> {'fuga' => '/hoge'}})

    # alert_module で一通りうまくいくか結合
#    Fluent::AlertOutput::SendMail.debug_mode true
#    alert_module = alert.create('type' => 'mail', 'match_tag_regexp' => '\.hoge$', 'format' => '{each hoge}{@fuga}{nl}{end}')
#    alert_module.emit('hoge.hoge', Time.now, {'hoge' => [{'fuga' => 'piyo'}, {'fuga' => 'poyo'}]})
  end
end

class AlertOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[


    <alert>
      match_tag_regexp \.config$
      type config
    </alert>
    <alert>
      match_regexp application.path ^\/hoge\/
      type mail
      to hoge@example.com
      format {@application}{hr}{each @log}{@file}:{@line}:{if @func}{@func}:{end} {@var}{nl}{end}{hr}{@pagebody}
    </alert>
    <alert>
      match_exists /tmp/hoge
      type drop
    </alert>
    <alert>
      match_tag_regexp \.fatal$
      type mail
      mailto fuga@example.com
      format {@application}{hr}{each @log}{@file}:{@line}:{if @func}{@func}:{end} {@var}{nl}{end}{hr}{@pagebody}
    </alert>
    <alert>
      type foward
      tag hoge.fuga
      add_key hoge fuga
    </alert>
  ]

  # CONFIG = %[
  #   path #{TMP_DIR}/out_file_test
  #   compress gz
  #   utc
  # ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::AlertOutput, tag).configure(conf)
  end

  def test_configure
    d = create_driver
#    assert_equal 5, d.instance.alert_list.size
#    assert_equal 3, outputs.size
#    assert_equal Fluent::TestOutput, outputs[0].class
#    assert_equal Fluent::TestOutput, outputs[1].class
#    assert_equal Fluent::TestOutput, outputs[2].class
#    assert_equal "c0", outputs[0].name
#    assert_equal "c1", outputs[1].name
#    assert_equal "c2", outputs[2].name

    #### set configurations
    # d = create_driver %[
    #   path test_path
    #   compress gz
    # ]
    #### check configurations
    # assert_equal 'test_path', d.instance.path
    # assert_equal :gz, d.instance.compress
  end

  def test_format
    d = create_driver

    # time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    # d.emit({"a"=>1}, time)
    # d.emit({"a"=>2}, time)

    # d.expect_format %[2011-01-02T13:14:15Z\ttest\t{"a":1}\n]
    # d.expect_format %[2011-01-02T13:14:15Z\ttest\t{"a":2}\n]

    # d.run
  end

  def test_write
    d = create_driver

    # time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    # d.emit({"a"=>1}, time)
    # d.emit({"a"=>2}, time)

    # ### FileOutput#write returns path
    # path = d.run
    # expect_path = "#{TMP_DIR}/out_file_test._0.log.gz"
    # assert_equal expect_path, path
  end

  def test_emit
    d = create_driver
  end
end

