# frozen_string_literal: true

RSpec.describe Rabarber::Cache do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    cache_store_was = Rails.cache
    cache_store_setting_was = Rails.application.config.cache_store

    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    Rails.application.config.cache_store = :memory_store

    example.run

    Rails.cache = cache_store_was
    Rails.application.config.cache_store = cache_store_setting_was
  end

  describe ".fetch" do
    context "when cache is enabled" do
      subject { described_class.fetch("foo", expires_in: 1.minute, race_condition_ttl: 5.seconds) { "bar" } }

      before { Rabarber.configure { |config| config.cache_enabled = true } }

      it "uses Rails.cache.fetch to cache the result of the provided block" do
        expect(Rails.cache).to receive(:fetch)
          .with("foo", { expires_in: 1.minute, race_condition_ttl: 5.seconds }).and_call_original
        subject
      end

      it "caches the result of the provided block" do
        subject
        expect(Rails.cache.read("foo")).to eq("bar")
      end

      it "returns the cached value" do
        expect(subject).to eq("bar")
      end

      it "returns the cached value on subsequent calls" do
        subject
        expect(described_class.fetch("foo", expires_in: 1.minute) { "baz" }).to eq("bar")
      end

      it "calls the provided block again when the cache expires" do
        subject
        expect(described_class.fetch("foo", expires_in: 1.minute) { "baz" }).to eq("bar")
        travel_to(2.minutes.from_now)
        expect(described_class.fetch("foo", expires_in: 1.minute) { "baz" }).to eq("baz")
      end
    end

    context "when cache is disabled" do
      subject { described_class.fetch("foo", expires_in: 1.minute) { "bar" } }

      before { Rabarber.configure { |config| config.cache_enabled = false } }

      it "does not use Rails.cache.fetch to cache the result of the provided block" do
        expect(Rails.cache).not_to receive(:fetch)
        subject
      end

      it "does not cache the result of the provided block" do
        subject
        expect(Rails.cache.read("foo")).to be_nil
      end

      it "returns the result of the provided block" do
        expect(subject).to eq("bar")
      end

      it "calls the provided block again on subsequent calls" do
        subject
        expect(described_class.fetch("foo", expires_in: 1.minute) { "baz" }).to eq("baz")
      end

      it "doesn't do anything when the cache expires" do
        subject
        expect(described_class.fetch("foo", expires_in: 1.minute) { "baz" }).to eq("baz")
        travel_to(2.minutes.from_now)
        expect(described_class.fetch("foo", expires_in: 1.minute) { "bad" }).to eq("bad")
      end
    end
  end

  describe ".delete" do
    subject { described_class.delete("foo", "bar") }

    context "when cache is enabled" do
      before { Rabarber.configure { |config| config.cache_enabled = true } }

      it "calls Rails.cache.delete_multi" do
        expect(Rails.cache).to receive(:delete_multi).with(["foo", "bar"]).and_call_original
        subject
      end

      it "deletes the cached value" do
        described_class.fetch("foo", expires_in: 1.minute) { "bar" }
        described_class.fetch("bar", expires_in: 1.minute) { "baz" }
        expect(Rails.cache.read("foo")).to eq("bar")
        expect(Rails.cache.read("bar")).to eq("baz")
        subject
        expect(Rails.cache.read("foo")).to be_nil
        expect(Rails.cache.read("bar")).to be_nil
      end
    end

    context "when cache is disabled" do
      before { Rabarber.configure { |config| config.cache_enabled = false } }

      it "does not call Rails.cache.delete" do
        expect(Rails.cache).not_to receive(:delete)
        subject
      end

      it "does not do anything" do
        described_class.fetch("foo", expires_in: 1.minute) { "bar" }
        expect(Rails.cache.read("foo")).to be_nil
        subject
        expect(Rails.cache.read("foo")).to be_nil
      end
    end
  end

  describe ".enabled?" do
    subject { described_class.enabled? }

    context "when cache is enabled" do
      before { Rabarber.configure { |config| config.cache_enabled = true } }

      it { is_expected.to be true }
    end

    context "when cache is disabled" do
      before { Rabarber.configure { |config| config.cache_enabled = false } }

      it { is_expected.to be false }
    end
  end

  describe ".key_for" do
    it "returns the cache key for the provided record id" do
      expect(described_class.key_for(123)).to eq("rabarber:roles_123")
    end
  end

  describe "ALL_ROLES_KEY" do
    it "is set to 'rabarber:roles'" do
      expect(described_class::ALL_ROLES_KEY).to eq("rabarber:roles")
    end
  end

  describe ".clear" do
    let(:keys) { ["rabarber:roles_1", "rabarber:roles_2", "rabarber:roles"] }

    before do
      Rabarber.configure { |config| config.cache_enabled = true }
      keys.each { |key| described_class.fetch(key, expires_in: 1.minute) { "foo" } }
    end

    it "deletes all keys that start with 'rabarber'" do
      keys.each { |key| expect(Rails.cache.exist?(key)).to be true }
      described_class.clear
      keys.each { |key| expect(Rails.cache.exist?(key)).to be false }
    end
  end
end
