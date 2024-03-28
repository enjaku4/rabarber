# frozen_string_literal: true

RSpec.describe Rabarber::Audit::Events::RolesAssigned do
  subject { described_class.trigger(roleable, roles_to_assign:, current_roles:) }

  let(:roles_to_assign) { [:admin, :manager] }
  let(:current_roles) { [:admin, :manager, :accountant] }

  context "when roleable is not nil" do
    let(:roleable) { User.create }

    it "logs the role assignment" do
      expect(Rabarber::Audit::Logger).to receive(:log).with(:info, "[Role Assignment] User with id: '#{roleable.id}' has been assigned the following roles: #{roles_to_assign}, current roles: #{current_roles}").and_call_original
      subject
    end
  end

  context "when roleable is nil" do
    let(:roleable) { nil }

    it "raises an error" do
      expect { subject }.to raise_error(Rabarber::Error, "Roleable is required for this event")
    end
  end
end
