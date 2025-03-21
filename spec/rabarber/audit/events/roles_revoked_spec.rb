# frozen_string_literal: true

RSpec.describe Rabarber::Audit::Events::RolesRevoked do
  subject { described_class.trigger(roleable, context:, roles_to_revoke:, current_roles:) }

  let(:project) { Project.create! }
  let(:context) { { context_type: "Project", context_id: project.id } }
  let(:roles_to_revoke) { [:admin, :manager] }
  let(:current_roles) { [:accountant] }
  let(:roleable) { User.create }

  it "logs the role revocation" do
    expect(Rabarber::Audit::Logger).to receive(:log).with(
      :info,
      "[Role Revocation] User##{roleable.id} | context: Project##{project.id} | revoked: #{roles_to_revoke} | current: #{current_roles}"
    ).and_call_original
    subject
  end

  context "when context is invalid" do
    let(:context) { 42 }

    it "raises an error" do
      expect { subject }.to raise_error(Rabarber::Error, "Unexpected context: 42")
    end
  end
end
