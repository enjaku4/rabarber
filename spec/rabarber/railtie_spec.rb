# frozen_string_literal: true

RSpec.describe Rabarber::Railtie do
  subject { DummyApplication.config.to_prepare_blocks.each(&:call) }

  it "checks the integrity and includes the Rabarber::HasRoles module" do
    expect(Rabarber::Core::IntegrityChecker).to receive(:run!)
    subject
    expect(User < Rabarber::HasRoles).to be true
  end
end
