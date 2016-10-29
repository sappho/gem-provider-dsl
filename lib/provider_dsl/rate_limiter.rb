module ProviderDSL
  # Simple rate limiter
  class RateLimiter
    def initialize(maximum_calls, time_period)
      @maximum_calls = maximum_calls
      @time_period = time_period
      reset
    end

    def wait
      if @call_countdown.zero?
        delta = Time.now - @timestamp
        sleep(@time_period - delta) if delta < @time_period
        reset
      end
      @call_countdown -= 1
    end

    private

    def reset
      @call_countdown = @maximum_calls
      @timestamp = Time.now
    end
  end
end
