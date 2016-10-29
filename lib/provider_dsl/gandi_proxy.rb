require 'gandi'
require 'provider_dsl/rate_limiter'
require 'provider_dsl/log'

module ProviderDSL
  module GandiProxy
    # Gandi allow 30 calls to their API every 2 seconds - http://doc.rpc.gandi.net/overview.html#rate-limit
    # To be safe we'll limit calls to no more than 20 every 2 seconds
    LIMITER = RateLimiter.new(20, 2)

    def method_missing(method, *arguments)
      result = super(method, *arguments)
      return result unless ::Gandi::VALID_METHODS.include?(chained.join('.'))
      Log.instance.debug((["-> Gandi #{method}"] + [*arguments]).join("\n  "))
      Log.instance.debug("Result:\n#{result}")
      LIMITER.wait
      result
    end
  end
end

module Gandi
  # Mix in this custom call handler to the standard Gandi client
  class ProxyCall
    prepend ProviderDSL::GandiProxy
  end
end
