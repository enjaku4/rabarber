# frozen_string_literal: true

RSpec.describe Rabarber::Audit::Events::UnauthorizedAttempt do
  subject { described_class.trigger(roleable, path: path) }

  let(:path) { "/admin" }

  context "when roleable is not nil" do
    let(:roleable) { User.create }

    before { roleable.assign_roles(:admin) }

    it "logs the unauthorized attempt" do
      expect(Rabarber::Audit::Logger).to receive(:log).with(:warn, "[Unauthorized Attempt] User##{roleable.id} | path: '#{path}'").and_call_original
      subject
    end
  end

  context "when roleable is nil" do
    let(:roleable) { nil }

    it "logs the unauthorized attempt" do
      expect(Rabarber::Audit::Logger).to receive(:log).with(:warn, "[Unauthorized Attempt] Unauthenticated user | path: '#{path}'").and_call_original
      subject
    end
  end
end
