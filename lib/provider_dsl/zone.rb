require 'ipaddress'
require 'provider_dsl/record'
require 'provider_dsl/log'

module ProviderDSL
  # Manage a DNS zone
  class Zone
    attr_reader :records

    def initialize(original_records, parameters = {})
      @logger = Log.instance
      @original_records = original_records.map do |record|
        if record.is_a?(Hash)
          Record.new(record['name'], record['type'], record['value'], record['ttl'])
        else
          record
        end
      end
      @records = parameters[:inherit_records] ? @original_records.clone : []
      @names = []
      name
      ttl
    end

    def create(&block)
      instance_eval(&block)
    end

    def name(name = nil, &block)
      new_names = name.nil? ? @names : [name] + @names
      effective_name(new_names)
      if block_given?
        saved_names = @names
        @names = new_names
        instance_eval(&block)
        @names = saved_names
        effective_name(@names)
      end
    end

    def ttl(ttl = 3600)
      @ttl = ttl
    end

    def aaaa(ip_addresses)
      record('AAAA', ip_addresses) do |ip_address|
        raise "#{ip_address} is not a valid IPv6 address" unless IPAddress.valid_ipv6?(ip_address)
        IPAddress(ip_address).compressed
      end
    end

    def a(ip_addresses)
      record('A', ip_addresses) do |ip_address|
        raise "#{ip_address} is not a valid IPv4 address" unless IPAddress.valid_ipv4?(ip_address)
        IPAddress(ip_address).octets.join('.')
      end
    end

    def cname(value)
      value = String(value)
      raise "CNAME #{value} cannot be defined for a naked domain" if @name == '@'
      record('CNAME', value) do
        @records = records.select { |other| !(other.type == 'CNAME' && other.name == @name) }
        value
      end
    end

    def mx(values)
      record('MX', values)
    end

    def txt(values)
      record('TXT', values)
    end

    def new_records
      records.select { |record| @original_records.select { |original| original == record }.count.zero? }
    end

    def removed_records
      @original_records.select { |original| records.select { |record| original == record }.count.zero? }
    end

    def changed?
      !(new_records + removed_records).count.zero?
    end

    def to_s(prefix = '', suffix = '')
      "#{prefix}#{sorted_records.join("#{suffix}\n#{prefix}")}#{suffix}"
    end

    def hash
      sorted_records.map(&:hash)
    end

    private

    def effective_name(names)
      @name = names.count.zero? ? '@' : names.join('.')
    end

    def record(type, values)
      values = Array(values)
      keepers = values.select { |value| value == '?' }.count
      if keepers > 0
        raise "Keeper ? flag is inconsistently used for #{@name} #{type} #{values}" if keepers != 1 || values.count != 1
        @original_records.select { |original| original.name == @name && original.type == type }.each do |original|
          add(original)
        end
      else
        values.each do |value|
          value = yield(value) if block_given?
          add(Record.new(@name, type, value, @ttl))
        end
      end
    end

    def add(record)
      @logger.log("Adding #{record}")
      @records = records.select { |other| !(record === other) } + [record]
    end

    def sorted_records
      records.sort_by { |record| [record.name, record.type, record.value] }
    end
  end
end
