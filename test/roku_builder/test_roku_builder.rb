# ********** Copyright Viacom, Inc. Apache 2.0 **********

require_relative "test_helper.rb"

module RokuBuilder
  class RokuBuilderTest < Minitest::Test
    def setup
      @ping = Minitest::Mock.new
      @options = build_options({sideload: true, device_given: false, working: true})
      @raw = {
        devices: {
        a: {ip: "2.2.2.2"},
        b: {ip: "3.3.3.3"}
      }
      }
      @parsed = {
        device_config: {ip: "1.1.1.1"}
      }
      @config = Config.new(options: @options)
      @config.instance_variable_set(:@config, @raw)
      @config.instance_variable_set(:@parsed, @parsed)
    end
    def teardown
      @ping.verify
    end

    def test_roku_builder_check_devices_good
      Net::Ping::External.stub(:new, @ping) do
        @ping.expect(:ping?, true, [@parsed[:device_config][:ip], 1, 0.2, 1])
        RokuBuilder.check_devices(options: @options, config: @config)
      end
    end
    def test_roku_builder_check_devices_no_devices
      Net::Ping::External.stub(:new, @ping) do
        @ping.expect(:ping?, false, [@parsed[:device_config][:ip], 1, 0.2, 1])
        @ping.expect(:ping?, false, [@raw[:devices][:a][:ip], 1, 0.2, 1])
        @ping.expect(:ping?, false, [@raw[:devices][:b][:ip], 1, 0.2, 1])
        assert_raises DeviceError do
          RokuBuilder.check_devices(options: @options, config: @config)
        end
      end
    end
    def test_roku_builder_check_devices_changed_device
      Net::Ping::External.stub(:new, @ping) do
        @ping.expect(:ping?, false, [@parsed[:device_config][:ip], 1, 0.2, 1])
        @ping.expect(:ping?, true, [@raw[:devices][:a][:ip], 1, 0.2, 1])
        RokuBuilder.check_devices(options: @options, config: @config)
        assert_equal @raw[:devices][:a][:ip], @config.parsed[:device_config][:ip]
      end
    end
    def test_roku_builder_check_devices_bad_device
      Net::Ping::External.stub(:new, @ping) do
        @options[:device_given] = true
        @ping.expect(:ping?, false, [@parsed[:device_config][:ip], 1, 0.2, 1])
        assert_raises DeviceError do
          RokuBuilder.check_devices(options: @options, config: @config)
        end
      end
    end
    def test_roku_builder_check_devices
      Net::Ping::External.stub(:new, @ping) do
        @options = build_options({build: true, device_given: false, working: true})
        RokuBuilder.check_devices(options: @options, config: @config)
      end
    end

    def test_roku_builder_run_debug
      tests = [
        {options: {debug: true}, method: :set_debug},
        {options: {verbose: true}, method: :set_info},
        {options: {}, method: :set_warn}
      ]
      tests.each do |test|
        logger = Minitest::Mock.new
        logger.expect(:call, nil)

        Logger.stub(test[:method], logger) do
          RokuBuilder.initialize_logger(options: test[:options])
        end

        logger.verify
      end
    end
    def test_roku_builder_options_parse_simple
      options = "a:b, c:d"
      options = RokuBuilder.options_parse(options: options)
      refute_nil options[:a]
      refute_nil options[:c]
      assert_equal "b", options[:a]
      assert_equal "d", options[:c]
    end
    def test_roku_builder_options_parse_complex
      options = "a:b:c, d:e:f"
      options = RokuBuilder.options_parse(options: options)
      refute_nil options[:a]
      refute_nil options[:d]
      assert_equal "b:c", options[:a]
      assert_equal "e:f", options[:d]
    end
  end
end
