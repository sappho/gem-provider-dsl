require 'gandi'
require 'provider_dsl/gandi_proxy'
require 'provider_dsl/zone'
require 'provider_dsl/record'
require 'provider_dsl/log'

module ProviderDSL
  # Gandi session factory
  class GandiSessionFactory
    def instance(api_key, environment)
      Gandi::Session.new(api_key, env: environment)
    end
  end

  # Manage a domain on Gandi
  class GandiProvider
    attr_reader :name_servers, :zone_name

    def initialize(api_key, parameters = {}, &block)
      session_factory = parameters[:session_factory] || GandiSessionFactory.new
      environment = parameters[:environment] || :production
      @domain_name = parameters[:domain_name]
      @logger = Log.instance
      @logger.confidential(/#{Regexp.quote(api_key)}/)
      @logger.log("Processing Gandi account in #{environment}")
      @session = session_factory.instance(api_key, environment)
      if @domain_name
        @logger.log("Domain name: #{@domain_name}")
        @name_servers = @session.domain.info(@domain_name).nameservers.uniq.sort
        @name_server_addresses =
          Hash[@session.domain.host.list(@domain_name).map { |data| [data['name'], data['ips'].uniq.sort] }]
      end
      @zone_name = nil
      @required_zone = []
      instance_eval(&block) if block_given?
    end

    def zone(zone_name, parameters = {}, &block)
      @logger.log("Zone: #{zone_name}")
      original_zone = @session.domain.zone.list.select { |data| data['name'] == zone_name }
      if original_zone.count.zero?
        zone_id = nil
        original_zone = []
      else
        zone_id = original_zone.first['id']
        original_zone = @session.domain.zone.record.list(zone_id, 0).map do |record|
          Record.new(record['name'], record['type'], record['value'], record['ttl'])
        end
      end
      if block_given?
        zone = Zone.new(original_zone, parameters)
        zone.create(&block)
        zone_id = original_zone.empty? ? @session.domain.zone.create(name: zone_name).id : zone_id
        if original_zone.empty? || zone.changed?
          @logger.log("Zone records:\n#{zone.to_s('  ')}")
          gandi_zone = []
          zone.records.each do |record|
            record.values.each do |value|
              gandi_zone << { name: record.name, type: record.type, value: value, ttl: record.ttl }
            end
          end
          version = @session.domain.zone.version.new(zone_id)
          @session.domain.zone.record.set(zone_id, version, gandi_zone)
          @session.domain.zone.version.set(zone_id, version)
          @logger.log("Created version #{version} of zone #{zone_name}")
        else
          @logger.log("Zone #{zone_name} is unchanged")
        end
      elsif original_zone.empty?
        raise "Zone #{zone_name} is undefined"
      end
      return unless @domain_name
      @logger.log("Attaching Gandi zone #{zone_name} to domain #{@domain_name}")
      @session.domain.zone.set(@domain_name, zone_id)
      name_servers!
    end

    def name_server_addresses(name_server)
      name_server = "#{name_server}.#{@domain_name}"
      @name_server_addresses.key?(name_server) ? @name_server_addresses[name_server] : []
    end

    def name_server_addresses!(name_server, required_name_server_addresses)
      current_name_server_addresses = name_server_addresses(name_server)
      required_name_server_addresses = Array(required_name_server_addresses).uniq.sort
      name_server = "#{name_server}.#{@domain_name}"
      return if current_name_server_addresses == required_name_server_addresses
      if @name_server_addresses.key?(name_server)
        @session.domain.host.update(name_server, required_name_server_addresses)
      else
        @session.domain.host.create(name_server, required_name_server_addresses)
      end
    end

    def name_servers!(required_name_servers = %w(a.dns.gandi.net b.dns.gandi.net c.dns.gandi.net))
      @name_servers = Array(required_name_servers).uniq.sort
      @logger.log((["Setting name servers for Gandi domain #{@domain_name} to:"] + @name_servers).join("\n  "))
      @session.domain.nameservers.set(@domain_name, @name_servers)
    end
  end
end
