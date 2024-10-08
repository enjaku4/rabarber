# frozen_string_literal: true

RSpec.describe Rabarber::Audit::Events::UnauthorizedAttempt do
  subject { described_class.trigger(roleable, path: "/admin", request_method: "DELETE") }

  context "when roleable is not null" do
    let(:roleable) { User.create.tap { |user| user.assign_roles(:admin) } }

    it "logs the unauthorized attempt" do
      expect(Rabarber::Audit::Logger).to receive(:log).with(
        :warn, "[Unauthorized Attempt] User##{roleable.id} | request: DELETE /admin"
      ).and_call_original
      subject
    end
  end

  context "when roleable is null" do
    let(:roleable) { Rabarber::Core::NullRoleable.new }

    it "logs the unauthorized attempt" do
      expect(Rabarber::Audit::Logger).to receive(:log).with(
        :warn, "[Unauthorized Attempt] Unauthenticated user | request: DELETE /admin"
      ).and_call_original
      subject
    end
  end
end
