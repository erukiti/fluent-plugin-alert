require 'helper.rb'

class FormatterTextTest < Test::Unit::TestCase
  def test_node_var
    f = Fluent::AlertOutput::FormatterText.new('')
    assert_equal 'hoge', f.node_var('test', {'test' => 'hoge'})
    assert_equal 'fuga', f.node_var('test', {'test' => 'fuga'})
    assert_equal "hoge\nfuga", f.node_var('test', {'test' => "hoge\nfuga"})
    assert_equal "hoge: fuga", f.node_var('test', {'test' => {'hoge' => 'fuga'}})
    assert_equal "hoge: fuga\npiyo: poyo", f.node_var('test', {'test' => {'hoge' => 'fuga', 'piyo' => 'poyo'}})
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
        format {@application|multiline}{hl}{each @log}{@file}:{@line}:{if @func}{@func}:{end}{@var|inline}{nl}{end}{hl}{@pagebody}
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

