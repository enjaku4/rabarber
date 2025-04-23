# frozen_string_literal: true

RSpec.describe Rabarber::Railtie do
  subject { initializer.run(DummyApplication) }

  let(:initializer) { described_class.initializers.detect { |i| i.name == "rabarber.after_initialize" } }
  let(:double) { instance_double(Rabarber::Core::PermissionsIntegrityChecker) }

  before do
    allow(Rabarber::Core::PermissionsIntegrityChecker).to receive(:new).and_return(double)
    allow(Rails.configuration).to receive(:eager_load).and_return(is_eager_load_enabled)
  end

  context "when eager_load is true" do
    let(:is_eager_load_enabled) { true }

    it "checks the integrity and includes the Rabarber::HasRoles module" do
      expect(double).to receive(:run!)
      subject
      expect(User < Rabarber::HasRoles).to be true
    end
  end

  context "when eager_load is false" do
    let(:is_eager_load_enabled) { false }

    it "does not check the integrity but still includes the Rabarber::HasRoles module" do
      expect(double).not_to receive(:run!)
      subject
      expect(User < Rabarber::HasRoles).to be true
    end
  end
end
