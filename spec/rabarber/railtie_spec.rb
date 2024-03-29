# frozen_string_literal: true

RSpec.describe Rabarber::Railtie do
  subject { described_class.initializers.detect { |i| i.name == "rabarber.after_initialize" }.run(DummyApplication) }

  context "when eager_load is true" do
    let(:double) { instance_double(Rabarber::Core::PermissionsIntegrityChecker) }

    before { allow(Rabarber::Core::PermissionsIntegrityChecker).to receive(:new).with(no_args).and_return(double) }

    it "checks the integrity" do
      expect(double).to receive(:run)
      subject
    end
  end

  context "when eager_load is false" do
    before { allow(Rails.configuration).to receive(:eager_load).and_return(false) }

    it "does not check the actions" do
      expect_any_instance_of(Rabarber::Core::PermissionsIntegrityChecker).not_to receive(:run)
      subject
    end
  end
end
