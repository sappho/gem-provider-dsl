require 'provider_dsl/gandi_provider'
require 'provider_dsl/google_cloud_provider'
require 'provider_dsl/log'

module ProviderDSL
  # The DSL processor
  class DSL
    def execute(glob = nil, &block)
      Dir[glob].each do |filename|
        Log.instance.log("DSL processing #{filename}")
        instance_eval(File.read(filename))
        Log.instance.log("DSL completed processing #{filename}")
      end if glob.is_a?(String)
      instance_eval(&block) if block_given?
    end

    def gandi(api_key, parameters = {}, &block)
      GandiProvider.new(api_key, parameters, &block)
    end

    def gcloud(project_name, key_filename, parameters = {}, &block)
      GoogleCloudProvider.new(project_name, key_filename, parameters, &block)
    end
  end
end
