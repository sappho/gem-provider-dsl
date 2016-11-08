require 'map'
require 'spec_helper'
require 'provider_dsl/google_cloud_provider'

describe ProviderDSL::GoogleCloudProvider do
  describe '#zone' do
    it 'manages a zone' do
      ProviderDSL::GoogleCloudProvider.new(
        'dns-services-1470233449157',
        '/Users/andrew/dev/chef/cookbook-ops-gcloud/files/default/etc/gcloud/DNS-Services-73d510671ba6.json'
      ) do
        zone 'podd.me.uk', 'A test zone' do
          mx '1 @'
          mx '2 mail.example.com.'
          txt '"v=spf1 include:_mailcust.gandi.net ~all"'
          name 'fred' do
            a '1.2.3.4'
          end
          name 'www' do
            cname '@'
          end
        end
      end
    end
  end
end
