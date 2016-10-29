module ProviderDSL
  # Manage a DNS record
  class Record
    attr_reader :name, :type, :value, :ttl, :hash

    def initialize(name, type, value, ttl)
      @name = name
      @type = type
      @value = value
      @ttl = ttl
      @hash = { name: name, type: type, value: value, ttl: ttl }
    end

    def to_s
      "#{ttl} #{name} #{type} #{value}"
    end

    def ==(other)
      self === other && ttl == other.ttl
    end

    def ===(other)
      name == other.name && type == other.type && value == other.value
    end
  end
end
