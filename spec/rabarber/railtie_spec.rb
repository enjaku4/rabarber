# frozen_string_literal: true

RSpec.describe Rabarber::Railtie do
  subject { DummyApplication.config.to_prepare_blocks.each(&:call) }

  it "checks the integrity and includes the Rabarber::HasRoles module" do
    expect(Rabarber::Core::IntegrityChecker).to receive(:run!)
    subject
    expect(User < Rabarber::HasRoles).to be true
  end

  it "does not reset permissions" do
    expect(Rabarber::Core::Permissions).not_to receive(:reset!)
    subject
  end
end
