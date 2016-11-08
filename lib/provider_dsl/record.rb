module ProviderDSL
  # Manage a DNS record
  class Record
    attr_reader :name, :type, :values, :ttl

    def initialize(name, type, values, ttl)
      @name = name
      @type = type
      @values = Array(values).map do |value|
        case type
        when 'AAAA'
          raise "#{value} is not a valid IPv6 address" unless IPAddress.valid_ipv6?(value)
          IPAddress(value).compressed
        when 'A'
          raise "#{value} is not a valid IPv4 address" unless IPAddress.valid_ipv4?(value)
          IPAddress(value).octets.join('.')
        when 'CNAME', 'MX', 'TXT'
          value
        else
          raise "Record #{name} #{type} has unhandled type"
        end
      end.uniq.sort
      @ttl = ttl
      raise "No values for record #{self}" if @values.empty?
      return unless type == 'CNAME'
      raise "Record #{self} must have only one value" if @values.count != 1
      raise "Record #{self} is invalid on the naked domain" if name == '@'
    end

    def to_s
      "#{ttl} #{name} #{type} #{values}"
    end

    def ==(other)
      self === other && ttl == other.ttl
    end

    def ===(other)
      same_name_and_type(other) && values == other.values
    end

    def same_name_and_type(other)
      name == other.name && type == other.type
    end
  end
end
