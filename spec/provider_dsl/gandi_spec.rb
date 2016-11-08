require 'map'
require 'spec_helper'
require 'provider_dsl/gandi_provider'
require 'provider_dsl/mocks/gandi_session'

describe ProviderDSL::GandiProvider do
  let(:domain_data_calls) do
    [
      {
        method: 'domain.info',
        parameters: %w(example.com),
        reply: Map.new(nameservers: %w(a.dns.gandi.net b.dns.gandi.net c.dns.gandi.net))
      },
      {
        method: 'domain.host.list',
        parameters: %w(example.com),
        reply: [
          Map.new(name: 'a.dns.gandi.net', ips: ['1.2.3.4']),
          Map.new(name: 'b.dns.gandi.net', ips: ['5.6.7.8']),
          Map.new(name: 'c.dns.gandi.net', ips: ['11.12.13.14'])
        ]
      }
    ]
  end
  describe '#name_servers' do
    it 'uses Gandi name servers' do
      gandi_session = ProviderDSL::MockGandiSession.new(domain_data_calls)
      session_factory = double('ProviderDSL::GandiSessionFactory')
      allow(session_factory).to receive(:instance).and_return(gandi_session)
      gandi = ProviderDSL::GandiProvider.new(
        'LdlLQkOBFGYqZGzWYqbv9sWo',
        session_factory: session_factory,
        domain_name: 'example.com'
      )
      expect(gandi.name_servers).to eq %w(a.dns.gandi.net b.dns.gandi.net c.dns.gandi.net)
      expect(domain_data_calls.count).to eq 0
    end
    it 'can set name servers' do
      expected_calls = domain_data_calls + [
        {
          method: 'domain.nameservers.set',
          parameters: ['example.com', %w(a.dns.gandi.net b.dns.gandi.net c.dns.gandi.net)],
          reply: nil
        }
      ]
      gandi_session = ProviderDSL::MockGandiSession.new(expected_calls)
      session_factory = double('ProviderDSL::GandiSessionFactory')
      allow(session_factory).to receive(:instance).and_return(gandi_session)
      gandi = ProviderDSL::GandiProvider.new(
        'LdlLQkOBFGYqZGzWYqbv9sWo',
        session_factory: session_factory,
        domain_name: 'example.com'
      )
      gandi.name_servers!(%w(a.dns.gandi.net b.dns.gandi.net c.dns.gandi.net))
      expect(expected_calls.count).to eq 0
    end
  end
  describe '#name_server_addresses!' do
    it 'can set name server addresses' do
      expected_calls = domain_data_calls + [
        {
          method: 'domain.host.create',
          parameters: ['test1.example.com', %w(1.2.3.4)],
          reply: nil
        }
      ]
      gandi_session = ProviderDSL::MockGandiSession.new(expected_calls)
      session_factory = double('ProviderDSL::GandiSessionFactory')
      allow(session_factory).to receive(:instance).and_return(gandi_session)
      gandi = ProviderDSL::GandiProvider.new(
        'LdlLQkOBFGYqZGzWYqbv9sWo',
        session_factory: session_factory,
        domain_name: 'example.com'
      )
      gandi.name_server_addresses!('test1', '1.2.3.4')
      expect(expected_calls.count).to eq 0
    end
  end
end
