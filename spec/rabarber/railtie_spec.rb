# frozen_string_literal: true

RSpec.describe Rabarber::Railtie do
  context "to_prepare" do
    subject { DummyApplication.config.to_prepare_blocks.each(&:call) }

    context "when eager_load is true" do
      it "includes the Rabarber::HasRoles module" do
        subject
        expect(User < Rabarber::HasRoles).to be true
      end

      it "does not reset permissions" do
        expect(Rabarber::Core::Permissions).not_to receive(:reset!)
        subject
      end

      it "does not add before_action to ApplicationController" do
        subject
        expect(ApplicationController._process_action_callbacks.any? { |callback| callback.kind == :before && callback.filter == :check_integrity }).to be false
      end
    end

    context "when eager_load is false" do
      before do
        allow(Rails.configuration).to receive(:eager_load).and_return(false)
        allow(Rabarber::Core::Permissions).to receive(:reset!)
      end

      after do
        ApplicationController.class_eval do
          skip_before_action :check_integrity
        end
      end

      it "includes the Rabarber::HasRoles module" do
        subject
        expect(User < Rabarber::HasRoles).to be true
      end

      it "resets permissions" do
        subject
        expect(Rabarber::Core::Permissions).to have_received(:reset!)
      end

      it "adds before_action to ApplicationController" do
        subject
        expect(ApplicationController._process_action_callbacks.any? { |callback| callback.kind == :before && callback.filter == :check_integrity }).to be true
      end
    end
  end

  context "after_initialize" do
    subject { initializer.run(DummyApplication) }

    let(:initializer) { described_class.initializers.detect { |i| i.name == "rabarber.after_initialize" } }

    before { allow(Rabarber::Core::IntegrityChecker).to receive(:run!) }

    context "when eager_load is true" do
      it "runs the Rabarber::Core::IntegrityChecker" do
        subject
        expect(Rabarber::Core::IntegrityChecker).to have_received(:run!)
      end
    end

    context "when eager_load is false" do
      before { allow(Rails.configuration).to receive(:eager_load).and_return(false) }

      it "does not run the Rabarber::Core::IntegrityChecker" do
        subject
        expect(Rabarber::Core::IntegrityChecker).not_to have_received(:run!)
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
