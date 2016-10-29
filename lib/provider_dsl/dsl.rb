require 'provider_dsl/gandi'
require 'provider_dsl/log'

module ProviderDSL
  # The DSL processor
  class DSL
    def initialize
      @logger = Log.instance
    end

    def execute(glob = nil, &block)
      Dir[glob].each do |filename|
        @logger.log("DSL processing #{filename}")
        instance_eval(File.read(filename))
        @logger.log("DSL completed processing #{filename}")
      end if glob.is_a?(String)
      instance_eval(&block) if block_given?
    end

    def gandi(parameters, &block)
      parameters[:session_factory] = GandiSessionFactory.new unless parameters.key?(:session_factory)
      Gandi.new(parameters, &block)
    end
  end
end
