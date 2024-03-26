# frozen_string_literal: true

RSpec.describe Rabarber::Missing::Actions do
  subject { described_class.new(controller).handle }

  after { Rabarber::Core::Permissions.action_rules.delete(DummyAuthController) }

  context "when controller is not specified" do
    let(:controller) { nil }

    context "when action is missing" do
      before { Rabarber::Core::Permissions.add(DummyAuthController, :index, [:admin], nil, nil) }

      it "raises error" do
        expect { subject }.to raise_error(
          Rabarber::Error, "'grant_access' method called with non-existent actions: [:index], context: 'DummyAuthController'"
        )
      end
    end
  end

  context "when controller is specified" do
    let(:controller) { DummyAuthController }

    context "when action is missing" do
      before { Rabarber::Core::Permissions.add(DummyAuthController, :index, [:admin], nil, nil) }

      it "raises error" do
        expect { subject }.to raise_error(
          Rabarber::Error, "'grant_access' method called with non-existent actions: [:index], context: 'DummyAuthController'"
        )
      end
    end
  end
end
