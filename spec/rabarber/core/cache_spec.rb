# frozen_string_literal: true

RSpec.describe Rabarber::Core::Cache do
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
    subject { described_class.fetch([id, context]) { "bar" } }

    let(:id) { 42 }
    let(:context) { { context_type: Project, context_id: 13 } }

    let(:default_options) { { expires_in: 1.hour, race_condition_ttl: 5.seconds } }

    let(:key) { described_class.prepare_key([42, context]) }

    context "when cache is enabled" do
      before { Rabarber.configure { |config| config.cache_enabled = true } }

      it "uses Rails.cache.fetch to cache the result of the provided block" do
        expect(Rails.cache).to receive(:fetch).with(key, **default_options).and_call_original
        subject
      end

      it "caches the result of the provided block" do
        subject
        expect(Rails.cache.read(key)).to eq("bar")
      end

      it "returns the cached value" do
        expect(subject).to eq("bar")
      end

      it "returns the cached value on subsequent calls" do
        subject
        expect(described_class.fetch([id, context]) { "baz" }).to eq("bar")
      end

      it "calls the provided block again when the cache expires" do
        subject
        expect(described_class.fetch([id, context]) { "baz" }).to eq("bar")
        travel_to(2.hours.from_now)
        expect(described_class.fetch([id, context]) { "baz" }).to eq("baz")
      end
    end

    context "when cache is disabled" do
      before { Rabarber.configure { |config| config.cache_enabled = false } }

      it "does not use Rails.cache.fetch to cache the result of the provided block" do
        expect(Rails.cache).not_to receive(:fetch)
        subject
      end

      it "does not cache the result of the provided block" do
        subject
        expect(Rails.cache.read(key)).to be_nil
      end

      it "returns the result of the provided block" do
        expect(subject).to eq("bar")
      end

      it "calls the provided block again on subsequent calls" do
        subject
        expect(described_class.fetch([id, context]) { "baz" }).to eq("baz")
      end

      it "doesn't do anything when the cache expires" do
        subject
        expect(described_class.fetch([42, context]) { "baz" }).to eq("baz")
        travel_to(2.hours.from_now)
        expect(described_class.fetch([42, context]) { "bad" }).to eq("bad")
      end
    end
  end

  describe ".delete" do
    subject { described_class.delete(*ids.map { [_1, context] }) }

    let(:ids) { [42, 13] }
    let(:context) { { context_type: Project, context_id: 13 } }

    let(:key42) { described_class.prepare_key([42, context]) }
    let(:key13) { described_class.prepare_key([13, context]) }

    context "when cache is enabled" do
      before { Rabarber.configure { |config| config.cache_enabled = true } }

      it "calls Rails.cache.delete_multi" do
        expect(Rails.cache).to receive(:delete_multi).with([key42, key13]).and_call_original
        subject
      end

      it "deletes the cached value" do
        described_class.fetch([42, context]) { "bar" }
        described_class.fetch([13, context]) { "baz" }
        expect(Rails.cache.read(key42)).to eq("bar")
        expect(Rails.cache.read(key13)).to eq("baz")
        subject
        expect(Rails.cache.read(key42)).to be_nil
        expect(Rails.cache.read(key13)).to be_nil
      end
    end

    context "when cache is disabled" do
      before { Rabarber.configure { |config| config.cache_enabled = false } }

      it "does not call Rails.cache.delete" do
        expect(Rails.cache).not_to receive(:delete)
        subject
      end

      it "does not do anything" do
        described_class.fetch([42, context]) { "bar" }
        expect(Rails.cache.read(key42)).to be_nil
        subject
        expect(Rails.cache.read(key42)).to be_nil
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
        described_class.fetch([42, context]) { "bar" }
        expect(Rails.cache.read(key42)).to eq("bar")
        subject
        expect(Rails.cache.read(key42)).to eq("bar")
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
    let(:context) { { context_type: Project, context_id: 13 } }

    let(:keys) { ids.map { |id| described_class.prepare_key([id, context]) } }

    before do
      Rabarber.configure { |config| config.cache_enabled = true }
      ids.each { |id| described_class.fetch([id, context]) { "foo" } }
    end

    it "deletes all keys that start with 'rabarber'" do
      keys.each { |key| expect(Rails.cache.exist?(key)).to be true }
      described_class.clear
      keys.each { |key| expect(Rails.cache.exist?(key)).to be false }
    end

    it "can be called from Rabarber::Cache" do
      allow(described_class).to receive(:clear)
      Rabarber::Cache.clear
      expect(described_class).to have_received(:clear)
    end
  end

  describe ".prepare_key" do
    subject { described_class.prepare_key([id, context]) }

    let(:id) { 42 }
    let(:context) { { context_type: Project, context_id: 13 } }

    it { is_expected.to eq("rabarber:4dfda2e866f925d97ea87d35c0bd7b3cb28b861e8df93081ce94d04b6634e87d") }
  end
end
