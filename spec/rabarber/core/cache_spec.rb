# frozen_string_literal: true

RSpec.describe Rabarber::Core::Cache, :memory_cache do
  include ActiveSupport::Testing::TimeHelpers

  describe ".fetch" do
    subject { described_class.fetch(roleable_id, scope) { "old" } }

    let(:roleable_id) { 42 }
    let(:scope) { { context_type: Project, context_id: 13 } }

    context "when cache is enabled" do
      before { Rabarber.configure { |config| config.cache_enabled = true } }

      it "caches the result of the provided block" do
        subject
        expect(described_class.fetch(roleable_id, scope) { "new" }).to eq("old")
      end

      it "caches the result of the provided block with an expiration time of 1 hour" do
        subject
        expect(described_class.fetch(roleable_id, scope) { "new" }).to eq("old")
        travel_to(2.hours.from_now)
        expect(described_class.fetch(roleable_id, scope) { "new" }).to eq("new")
      end

      context "when called within a transaction" do
        before { described_class.fetch(roleable_id, scope) { "cached" } }

        it "neither reads nor fills the cache" do
          ActiveRecord::Base.transaction do
            expect(described_class.fetch(roleable_id, scope) { "fresh" }).to eq("fresh")
            expect(described_class.fetch(43, scope) { "uncommitted" }).to eq("uncommitted")
          end

          expect(described_class.fetch(roleable_id, scope) { "new" }).to eq("cached")
          expect(described_class.fetch(43, scope) { "new" }).to eq("new")
        end
      end

      context "when called within a transaction other code can't join, like the one Rails opens around each test" do
        it "caches the result of the provided block" do
          ActiveRecord::Base.transaction(joinable: false) { subject }
          expect(described_class.fetch(roleable_id, scope) { "new" }).to eq("old")
        end
      end
    end

    context "when cache is disabled" do
      before { Rabarber.configure { |config| config.cache_enabled = false } }

      it "does not cache the result of the provided block" do
        subject
        expect(described_class.fetch(roleable_id, scope) { "new" }).to eq("new")
      end
    end
  end

  describe ".delete" do
    subject { described_class.delete(*roleable_ids.map { [_1, scope] }) }

    let(:roleable_ids) { [42, 13] }
    let(:scope) { { context_type: Project, context_id: 13 } }

    context "when cache is enabled" do
      before { Rabarber.configure { |config| config.cache_enabled = true } }

      it "deletes the cached value" do
        described_class.fetch(42, scope) { "foo" }
        described_class.fetch(13, scope) { "bar" }
        expect(described_class.fetch(42, scope)).to eq("foo")
        expect(described_class.fetch(13, scope)).to eq("bar")
        subject
        expect(described_class.fetch(42, scope)).to be_nil
        expect(described_class.fetch(13, scope)).to be_nil
      end

      it "reads the cache version once for all entries" do
        described_class.fetch(42, scope) { "foo" }
        allow(Rails.cache).to receive(:read).and_call_original
        subject
        expect(Rails.cache).to have_received(:read).once
      end

      context "when called within a transaction" do
        before { described_class.fetch(42, scope) { "foo" } }

        it "deletes the cached value after commit" do
          ActiveRecord::Base.transaction { subject }
          expect(described_class.fetch(42, scope)).to be_nil
        end

        it "keeps the cached value when the transaction is rolled back" do
          ActiveRecord::Base.transaction do
            subject
            raise ActiveRecord::Rollback
          end

          expect(described_class.fetch(42, scope) { "new" }).to eq("foo")
        end
      end
    end
  end

  describe ".clear" do
    let(:roleable_ids) { [1, 2, 42] }
    let(:scope) { { context_type: Project, context_id: 13 } }

    before do
      Rabarber.configure { |config| config.cache_enabled = true }
      roleable_ids.each { |id| described_class.fetch(id, scope) { "old-#{id}" } }
    end

    it "invalidates all cached entries" do
      roleable_ids.each { |id| expect(described_class.fetch(id, scope) { "new-#{id}" }).to eq("old-#{id}") }
      described_class.clear
      roleable_ids.each { |id| expect(described_class.fetch(id, scope) { "new-#{id}" }).to eq("new-#{id}") }
    end

    context "when called within a transaction" do
      it "invalidates all cached entries after commit" do
        ActiveRecord::Base.transaction { described_class.clear }
        roleable_ids.each { |id| expect(described_class.fetch(id, scope) { "new-#{id}" }).to eq("new-#{id}") }
      end

      it "keeps all cached entries when the transaction is rolled back" do
        ActiveRecord::Base.transaction do
          described_class.clear
          raise ActiveRecord::Rollback
        end

        roleable_ids.each { |id| expect(described_class.fetch(id, scope) { "new-#{id}" }).to eq("old-#{id}") }
      end
    end

    it "can be called from Rabarber::Cache" do
      allow(described_class).to receive(:clear)
      Rabarber::Cache.clear
      expect(described_class).to have_received(:clear)
    end
  end
end
