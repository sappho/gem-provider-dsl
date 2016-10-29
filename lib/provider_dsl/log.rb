require 'singleton'

module ProviderDSL
  # A simple logger
  class Log
    include Singleton

    attr_accessor :callback, :debug

    def initialize
      @log = []
      @confidential = []
      @callback = nil
      @debug = ENV['DSL_DEBUG'] == 'true'
    end

    def log(message)
      @confidential.each { |regex| message.gsub!(regex, '******') }
      @log << message
      @callback.call(message) unless @callback.nil?
    end

    def debug(message)
      log(message) if @debug
    end

    def confidential(regex)
      @confidential << regex
      @confidential.uniq!
    end

    def to_s
      @log.join("\n")
    end
  end
end
