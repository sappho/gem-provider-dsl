require 'ipaddress'
require 'provider_dsl/record'
require 'provider_dsl/log'

module ProviderDSL
  # Manage a DNS zone
  class Zone
    attr_reader :records

    def initialize(original_records, parameters = {})
      @logger = Log.instance
      @original_records = []
      @records = []
      original_records.each do |record|
        @original_records = add(@original_records, record)
        @records = add(@records, record) if parameters[:inherit_records]
      end
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
      record('AAAA', ip_addresses)
    end

    def a(ip_addresses)
      record('A', ip_addresses)
    end

    def cname(value)
      record('CNAME', value)
    end

    def mx(values)
      record('MX', values)
    end

    def txt(values)
      record('TXT', values)
    end

    def new_or_changed_records
      records.select { |record| @original_records.select { |original| original == record }.count.zero? }
    end

    def removed_records
      @original_records.select do |original|
        records.select { |record| original == record }.count.zero?
      end
    end

    def changed?
      !(new_or_changed_records + removed_records).count.zero?
    end

    def to_s(prefix = '', suffix = '')
      "#{prefix}#{records.join("#{suffix}\n#{prefix}")}#{suffix}"
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
          @records = add(@records, original)
        end
      else
        @records =
          add(@records, Record.new(@name, type, values.map { |value| block_given? ? yield(value) : value }, @ttl))
      end
    end

    def add(records, record)
      @logger.log("Adding #{record}")
      values = record.values
      records = records.select do |other|
        match = record.same_name_and_type(other)
        values = other.values + values if match
        !match
      end
      values = values.last if record.type == 'CNAME'
      records << Record.new(record.name, record.type, values, record.ttl)
      records.sort_by { |sort| [sort.name, sort.type] }
    end
  end
end
