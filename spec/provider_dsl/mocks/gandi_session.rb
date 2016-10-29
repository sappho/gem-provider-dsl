require 'gandi'

module ProviderDSL
  class MockProxyCall
    def initialize(calls)
      @calls = calls
      @chained = []
      self
    end

    undef_method :clone

    def method_missing(method, *parameters)
      @chained << method
      method_name = @chained.join('.')
      if ::Gandi::VALID_METHODS.include?(method_name)
        raise 'Too many Gandi API calls' if @calls.count.zero?
        call = @calls.shift
        expected_method = call[:method]
        raise "Gandi API #{method_name} should have been #{expected_method}" if method_name != expected_method
        raise "Gandi API #{method_name} called with incorrect parameters" if parameters != call[:parameters]
        call[:reply]
      else
        self
      end
    end
  end

  # Simple rate limiter
  class MockGandiSession
    def initialize(calls)
      @calls = calls
    end

    def list_methods
    end

    def method_signature(name)
    end

    def method_help(name)
    end

    def method_missing(method, *args)
      MockProxyCall.new(@calls).send(method, *args)
    end
  end
end
