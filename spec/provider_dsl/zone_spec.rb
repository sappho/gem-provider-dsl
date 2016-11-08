require 'spec_helper'
require 'provider_dsl/zone'

describe ProviderDSL::Zone do
  describe '#changed?' do
    it 'fails naked domain CNAME records' do
      zone = ProviderDSL::Zone.new([])
      expect { zone.cname('x') }.to raise_exception 'Record 3600 @ CNAME ["x"] is invalid on the naked domain'
    end
    it 'builds valid zones' do
      zone = ProviderDSL::Zone.new([])
      zone.create do
        a '1.2.3.4'
        name 'sub' do
          a '1.1.1.1'
        end
      end
      expect(zone.changed?).to eq true
      expect(zone.records.count).to eq 2
      expect(zone.new_or_changed_records.count).to eq 2
      expect(zone.removed_records.count).to eq 0
      expect(zone.to_s).to eq "3600 @ A [\"1.2.3.4\"]\n3600 sub A [\"1.1.1.1\"]"
      zone = ProviderDSL::Zone.new(zone.records)
      zone.create do
        a '1.2.3.4'
      end
      expect(zone.changed?).to eq true
      expect(zone.records.count).to eq 1
      expect(zone.new_or_changed_records.count).to eq 0
      expect(zone.removed_records.count).to eq 1
      expect(zone.to_s).to eq '3600 @ A ["1.2.3.4"]'
      zone = ProviderDSL::Zone.new(zone.records)
      zone.create do
        a '1.2.3.4'
        name 'sub' do
          cname 'a'
          cname 'b'
        end
      end
      expect(zone.changed?).to eq true
      expect(zone.records.count).to eq 2
      expect(zone.new_or_changed_records.count).to eq 1
      expect(zone.removed_records.count).to eq 0
      expect(zone.to_s).to eq "3600 @ A [\"1.2.3.4\"]\n3600 sub CNAME [\"b\"]"
      zone = ProviderDSL::Zone.new(zone.records)
      zone.create do
        a '1.2.3.4'
        name 'sub' do
          cname 'a'
        end
      end
      expect(zone.changed?).to eq true
      expect(zone.records.count).to eq 2
      expect(zone.new_or_changed_records.count).to eq 1
      expect(zone.removed_records.count).to eq 1
      expect(zone.to_s).to eq "3600 @ A [\"1.2.3.4\"]\n3600 sub CNAME [\"a\"]"
      zone = ProviderDSL::Zone.new(zone.records)
      zone.create do
        ttl 600
        a '1.2.3.4'
        ttl
        name 'sub' do
          cname 'a'
        end
      end
      expect(zone.changed?).to eq true
      expect(zone.records.count).to eq 2
      expect(zone.new_or_changed_records.count).to eq 1
      expect(zone.removed_records.count).to eq 1
      expect(zone.to_s).to eq "600 @ A [\"1.2.3.4\"]\n3600 sub CNAME [\"a\"]"
      zone = ProviderDSL::Zone.new(zone.records)
      zone.create do
        ttl 600
        a '1.2.3.4'
        a '2.3.4.5'
        a '1.2.3.4'
        ttl
        name 'sub' do
          cname 'a'
        end
      end
      expect(zone.changed?).to eq true
      expect(zone.records.count).to eq 2
      expect(zone.new_or_changed_records.count).to eq 1
      expect(zone.removed_records.count).to eq 1
      expect(zone.to_s).to eq "600 @ A [\"1.2.3.4\", \"2.3.4.5\"]\n3600 sub CNAME [\"a\"]"
      zone = ProviderDSL::Zone.new(zone.records)
      zone.create do
        ttl 600
        a '1.2.3.4'
        a '2.3.4.5'
        ttl
        name 'sub' do
          cname 'a'
        end
      end
      expect(zone.changed?).to eq false
      expect(zone.records.count).to eq 2
      expect(zone.new_or_changed_records.count).to eq 0
      expect(zone.removed_records.count).to eq 0
      expect(zone.to_s).to eq "600 @ A [\"1.2.3.4\", \"2.3.4.5\"]\n3600 sub CNAME [\"a\"]"
      zone = ProviderDSL::Zone.new(zone.records)
      zone.create do
        ttl 300
        mx '10 smtp'
        ttl 600
        a '1.2.3.4'
        a '2.3.4.5'
        ttl
        name 'sub' do
          cname 'a'
        end
      end
      expect(zone.changed?).to eq true
      expect(zone.records.count).to eq 3
      expect(zone.new_or_changed_records.count).to eq 1
      expect(zone.removed_records.count).to eq 0
      expect(zone.to_s).to eq "600 @ A [\"1.2.3.4\", \"2.3.4.5\"]\n300 @ MX [\"10 smtp\"]\n3600 sub CNAME [\"a\"]"
    end
  end
end
