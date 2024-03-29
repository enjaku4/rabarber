# frozen_string_literal: true

RSpec.describe Rabarber::Audit::Events::RolesRevoked do
  subject { described_class.trigger(roleable, roles_to_revoke:, current_roles:) }

  let(:roles_to_revoke) { [:admin, :manager] }
  let(:current_roles) { [:accountant] }

  context "when roleable is not nil" do
    let(:roleable) { User.create }

    it "logs the role revocation" do
      expect(Rabarber::Audit::Logger).to receive(:log).with(:info, "[Role Revocation] User with id: '#{roleable.id}' has been revoked from the following roles: #{roles_to_revoke}, current roles: #{current_roles}").and_call_original
      subject
    end
  end

  context "when roleable is nil" do
    let(:roleable) { nil }

    it "raises an error" do
      expect { subject }.to raise_error(ArgumentError, "Roleable is required for Rabarber::Audit::Events::RolesRevoked event")
    end
  end
end
