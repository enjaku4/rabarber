# frozen_string_literal: true

RSpec.describe Rabarber::Audit::Events::RolesAssigned do
  subject { described_class.trigger(roleable, context:, roles_to_assign:, current_roles:) }

  let(:context) { { context_type: nil, context_id: nil } }
  let(:roles_to_assign) { [:admin, :manager] }
  let(:current_roles) { [:admin, :manager, :accountant] }
  let(:roleable) { User.create }

  it "logs the role assignment" do
    expect(Rabarber::Audit::Logger).to receive(:log).with(
      :info,
      "[Role Assignment] User##{roleable.id} | context: Global | assigned: #{roles_to_assign} | current: #{current_roles}"
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
