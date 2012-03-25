# coding: utf-8
require 'helper.rb'

class FormatterTextTest < Test::Unit::TestCase
  def test_output_var
    ## 文字列
    # 文字列単品
    f = Fluent::AlertOutput::FormatterText.new("")
    f.output_var "hoge"
    assert_equal "\"hoge\"\n", f.text

    # 複数行文字列
    f.text = ""
    f.output_var "multiline\nstring"
    assert_equal "\"multiline\\n\n string\"\n", f.text

    # 複数行文字列(3行)
    f.text = ""
    f.output_var "multiline\n3lines\nstring"
    assert_equal "\"multiline\\n\n 3lines\\n\n string\"\n", f.text

    # 継続状態、文字列単品"
    f.text = "hoge.html:80: "
    f.output_var "hoge"
	assert_equal "hoge.html:80: \"hoge\"\n", f.text

    # 継続状態、複数行文字列
    f.text = "hoge.html:80: "
    f.output_var "multiline\nstring"
	assert_equal "hoge.html:80: \"multiline\\n\n               string\"\n", f.text

    # 継続状態(\n含む)、文字列単品
    f.text = "hoge\nfuga: "
    f.output_var "piyo"
    assert_equal "hoge\nfuga: \"piyo\"\n", f.text

    # 継続状態(\n含む)、複数行文字列
    f.text = "hogehoge\nfuga: "
    f.output_var "multiline\nstring"
    assert_equal "hogehoge\nfuga: \"multiline\\n\n       string\"\n", f.text

	## 自分がHash/Array, 子が文字列
    # Hash, 文字列単品
    f.text = ""
    f.output_var("hoge" => "ほげ")
    assert_equal "hoge: \"ほげ\"\n", f.text

    # Hash, 複数行文字列
    f.text = ""
    f.output_var("hoge" => "multiline\nstring")
    assert_equal "hoge: \"multiline\\n\n       string\"\n", f.text

    # Hash複数, 文字列単品＆複数行文字列
    f.text = ""
    f.output_var("hoge" => "ほげ", "fuga" => "multiline\nstring")
    assert_equal "hoge: \"ほげ\"\nfuga: \"multiline\\n\n       string\"\n", f.text

    # 継続状態、Hash複数, 文字列単品＆複数行文字列
    f.text = "hoge.html:80: "
    f.output_var("hoge" => "ほげ", "fuga" => "multiline\nstring")
    assert_equal "hoge.html:80: \n  hoge: \"ほげ\"\n  fuga: \"multiline\\n\n         string\"\n", f.text

    # Array, 文字列単品
    f.text = ""
    f.output_var(["ほげ", "ふが"])
    assert_equal "0: \"ほげ\"\n1: \"ふが\"\n", f.text

    # Array, 複数行文字列
    f.text = ""
    f.output_var(["ほげ", "multiline\nstring"])
    assert_equal "0: \"ほげ\"\n1: \"multiline\\n\n    string\"\n", f.text

    ## 自分がHash/Array, 子がHash/Array
    

  end

end

class AlertOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    <alert>
      match_regexp application.path \/hoge\/fuga.*
      <action>
        type add
        key hoge
        filed test_hoge
      </action>
      <action>
        type format_text
        format {@application}{hl}{each @log}{@file}:{@line}:{if @func}{@func}:{end} {@var}{nl}{end}{hl}{@pagebody}
      </action>
      <action>
        type tag
        tag mail.alert
      </action>
    </alert>
    <alert>
      match_exists /tmp/hoge
      <action>
        type drop
      </action>
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

  def test_match_regexp
    d = create_driver

#    assert_equal true, d.instance.match_regexp('hoge', 'hoge')
#    assert_equal false, d.instance.match_regexp('^hoge', 'fuga')
  end






  def test_configure
    d = create_driver

#    outputs = d.instance.outputs
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

