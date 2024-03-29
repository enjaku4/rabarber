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
    subject { described_class.fetch(42, expires_in: 1.hour, race_condition_ttl: 5.seconds) { "bar" } }

    context "when cache is enabled" do
      before { Rabarber.configure { |config| config.cache_enabled = true } }

      it "uses Rails.cache.fetch to cache the result of the provided block" do
        expect(Rails.cache).to receive(:fetch)
          .with("rabarber:roles_42", expires_in: 1.hour, race_condition_ttl: 5.seconds).and_call_original
        subject
      end

      it "caches the result of the provided block" do
        subject
        expect(Rails.cache.read("rabarber:roles_42")).to eq("bar")
      end

      it "returns the cached value" do
        expect(subject).to eq("bar")
      end

      it "returns the cached value on subsequent calls" do
        subject
        expect(described_class.fetch(42, expires_in: 1.minute) { "baz" }).to eq("bar")
      end

      it "calls the provided block again when the cache expires" do
        subject
        expect(described_class.fetch(42, expires_in: 1.minute) { "baz" }).to eq("bar")
        travel_to(2.hours.from_now)
        expect(described_class.fetch(42, expires_in: 1.hour) { "baz" }).to eq("baz")
      end
    end

    context "when cache is disabled" do
      subject { described_class.fetch(42, expires_in: 1.minute) { "bar" } }

      before { Rabarber.configure { |config| config.cache_enabled = false } }

      it "does not use Rails.cache.fetch to cache the result of the provided block" do
        expect(Rails.cache).not_to receive(:fetch)
        subject
      end

      it "does not cache the result of the provided block" do
        subject
        expect(Rails.cache.read("rabarber:roles_42")).to be_nil
      end

      it "returns the result of the provided block" do
        expect(subject).to eq("bar")
      end

      it "calls the provided block again on subsequent calls" do
        subject
        expect(described_class.fetch(42, expires_in: 1.minute) { "baz" }).to eq("baz")
      end

      it "doesn't do anything when the cache expires" do
        subject
        expect(described_class.fetch(42, expires_in: 1.minute) { "baz" }).to eq("baz")
        travel_to(2.minutes.from_now)
        expect(described_class.fetch(42, expires_in: 1.minute) { "bad" }).to eq("bad")
      end
    end
  end

  describe ".delete" do
    subject { described_class.delete(*ids) }

    context "when cache is enabled" do
      let(:ids) { [42, 13] }

      before { Rabarber.configure { |config| config.cache_enabled = true } }

      it "calls Rails.cache.delete_multi" do
        expect(Rails.cache).to receive(:delete_multi).with(["rabarber:roles_42", "rabarber:roles_13"]).and_call_original
        subject
      end

      it "deletes the cached value" do
        described_class.fetch(42, expires_in: 1.minute) { "bar" }
        described_class.fetch(13, expires_in: 1.minute) { "baz" }
        expect(Rails.cache.read("rabarber:roles_42")).to eq("bar")
        expect(Rails.cache.read("rabarber:roles_13")).to eq("baz")
        subject
        expect(Rails.cache.read("rabarber:roles_42")).to be_nil
        expect(Rails.cache.read("rabarber:roles_13")).to be_nil
      end
    end

    context "when cache is disabled" do
      let(:ids) { [42, 13] }

      before { Rabarber.configure { |config| config.cache_enabled = false } }

      it "does not call Rails.cache.delete" do
        expect(Rails.cache).not_to receive(:delete)
        subject
      end

      it "does not do anything" do
        described_class.fetch(42, expires_in: 1.minute) { "bar" }
        expect(Rails.cache.read("rabarber:roles_42")).to be_nil
        subject
        expect(Rails.cache.read("rabarber:roles_42")).to be_nil
      end
    end

    context "when no roleable ids are provided" do
      let(:ids) { [] }

      before { Rabarber.configure { |config| config.cache_enabled = true } }

      it "does not call Rails.cache.delete" do
        expect(Rails.cache).not_to receive(:delete)
        subject
      end

      it "does not do anything" do
        described_class.fetch(42, expires_in: 1.minute) { "bar" }
        expect(Rails.cache.read("rabarber:roles_42")).to eq("bar")
        subject
        expect(Rails.cache.read("rabarber:roles_42")).to eq("bar")
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

  describe ".clear" do
    let(:ids) { [1, 2, 42] }
    let(:keys) { ["rabarber:roles_1", "rabarber:roles_2", "rabarber:roles_42"] }

    before do
      Rabarber.configure { |config| config.cache_enabled = true }
      ids.each { |id| described_class.fetch(id, expires_in: 1.minute) { "foo" } }
    end

    it "deletes all keys that start with 'rabarber'" do
      keys.each { |key| expect(Rails.cache.exist?(key)).to be true }
      described_class.clear
      keys.each { |key| expect(Rails.cache.exist?(key)).to be false }
    end
  end
end
