require 'google/cloud'
require 'provider_dsl/zone'
require 'provider_dsl/record'
require 'provider_dsl/log'

module ProviderDSL
  # Google Cloud session factory
  class GCloudSessionFactory
    def instance(project_name, key_filename, parameters)
      Google::Cloud.new(
        project_name, key_filename,
        timeout: parameters[:timeout] || 0, retries: parameters[:retries] || 0
      )
    end
  end

  # Manage a domain on Google Cloud
  class GoogleCloudProvider
    EXCLUDE = %w(SOA NS).freeze

    def initialize(project_name, key_filename, parameters = {}, &block)
      session_factory = parameters[:session_factory] || GCloudSessionFactory.new
      @logger = Log.instance
      @logger.log("Processing Google Cloud project #{project_name}")
      @dns = session_factory.instance(project_name, key_filename, parameters).dns
      instance_eval(&block) if block_given?
    end

    def zone(domain_name, description, parameters = {}, &block)
      zone_name = domain_name.tr('.', '-')
      zone_style_domain_name = "#{domain_name}."
      domain_name_regex = Regexp.quote(zone_style_domain_name)
      @logger.log("Zone: #{zone_name} for domain #{domain_name}")
      if @dns.zones.select { |zone| zone.name == zone_name }.count.zero?
        gcloud_zone = nil
        zone = Zone.new([], parameters)
      else
        gcloud_zone = @dns.zone(zone_name)
        records = gcloud_zone.records
        records = records.map do |record|
          unless record.name =~ /^(|([a-zA-Z0-9\-\.]+)\.)#{domain_name_regex}$/
            raise "Google Cloud returned invalid record name #{record.name}"
          end
          name = Regexp.last_match(1).empty? ? '@' : Regexp.last_match(2)
          data = record.data.map do |value|
            if %w(CNAME MX).include?(record.type)
              if value =~ /^((|[0-9]+ +)[a-zA-Z0-9\-\.]+)\.#{domain_name_regex}$/
                value = Regexp.last_match(1)
              end
            end
            value
          end
          EXCLUDE.include?(record.type) ? nil : Record.new(name, record.type, data, record.ttl)
        end
        zone = Zone.new(records.select { |record| record }, parameters)
      end
      zone.create(&block)
      if gcloud_zone.nil? || zone.changed?
        @logger.log("Zone records:\n#{zone.to_s('  ')}")
        unless gcloud_zone
          gcloud_zone = @dns.create_zone(zone_name, zone_style_domain_name, description: description)
          @logger.log("Created zone #{zone_name}")
        end
        deletions = []
        additions = []
        zone.removed_records.each do |record|
          # gcloud_zone.remove(record.name, record.type)
          deletions << dns_record(record, zone_style_domain_name)
          @logger.log("Removing #{record}")
        end
        zone.new_or_changed_records.each do |record|
          # gcloud_zone.replace(record.name, record.type, record.ttl, record.values)
          additions << dns_record(record, zone_style_domain_name)
          @logger.log("Creating or replacing #{record}")
        end
        gcloud_zone.update(additions, deletions)
      else
        @logger.log("Zone #{zone_name} is unchanged")
      end
    end

    private

    def dns_record(record, zone_style_domain_name)
      name = record.name != '@' ? "#{record.name}.#{zone_style_domain_name}" : zone_style_domain_name
      if %w(CNAME MX).include?(record.type)
        data = record.values.map do |value|
          if value.end_with?('.')
            value
          else
            "#{value == '@' ? '' : "#{name}."}#{zone_style_domain_name}"
          end
        end
      else
        data = record.values
      end
      Google::Cloud::Dns::Record.new(name, record.type, record.ttl, data)
    end
  end
end
