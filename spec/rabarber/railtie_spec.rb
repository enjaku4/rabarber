# frozen_string_literal: true

RSpec.describe Rabarber::Railtie do
  # TODO: perhaps this should be tested differently
  context "to_prepare" do
    subject { DummyApplication.config.to_prepare_blocks.each(&:call) }

    context "when eager_load is true" do
      it "does not reset permissions" do
        expect(Rabarber::Core::Permissions).not_to receive(:reset!)
        subject
      end
    end

    context "when eager_load is false" do
      before do
        allow(Rails.configuration).to receive(:eager_load).and_return(false)
        allow(Rabarber::Core::Permissions).to receive(:reset!)
      end

      it "resets permissions" do
        subject
        expect(Rabarber::Core::Permissions).to have_received(:reset!)
      end
    end
  end

  context "extend_migration_helpers" do
    subject { initializer.run(DummyApplication) }

    let(:initializer) { described_class.initializers.detect { |i| i.name == "rabarber.extend_migration_helpers" } }

    before do
      allow(ActiveSupport).to receive(:on_load).with(:active_record).and_yield
      allow(ActiveRecord::Migration).to receive(:include)
    end

    it "includes Rabarber::MigrationHelpers in ActiveRecord::Migration" do
      subject
      expect(ActiveRecord::Migration).to have_received(:include).with(Rabarber::MigrationHelpers)
    end
  end
end
