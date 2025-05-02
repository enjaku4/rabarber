# frozen_string_literal: true

RSpec.describe Rabarber::Railtie do
  context "to_prepare" do
    subject { DummyApplication.config.to_prepare_blocks.each(&:call) }

    context "when eager_load is true" do
      it "includes the Rabarber::HasRoles module" do
        expect(User < Rabarber::HasRoles).to be true
      end

      it "does not reset permissions" do
        expect(Rabarber::Core::Permissions).not_to receive(:reset!)
        subject
      end
    end

    context "when eager_load is false" do
      before { allow(Rails.configuration).to receive(:eager_load).and_return(false) }

      it "includes the Rabarber::HasRoles module" do
        expect(User < Rabarber::HasRoles).to be true
      end

      it "resets permissions" do
        expect(Rabarber::Core::Permissions).to receive(:reset!)
        subject
      end
    end
  end

  context "after_initialize" do
    subject { initializer.run(DummyApplication) }

    let(:initializer) { described_class.initializers.detect { |i| i.name == "rabarber.after_initialize" } }

    context "when eager_load is true" do
      it "runs the Rabarber::Core::IntegrityChecker" do
        expect(Rabarber::Core::IntegrityChecker).to receive(:run!)
        subject
      end
    end

    context "when eager_load is false" do
      before { allow(Rails.configuration).to receive(:eager_load).and_return(false) }

      it "does not run the Rabarber::Core::IntegrityChecker" do
        expect(Rabarber::Core::IntegrityChecker).not_to receive(:run!)
        subject
      end
    end
  end
end
