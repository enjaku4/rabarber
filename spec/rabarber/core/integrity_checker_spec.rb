# frozen_string_literal: true

RSpec.describe Rabarber::Core::IntegrityChecker do
  subject { described_class.run! }

  context "checking missing actions" do
    after { Rabarber::Core::Permissions.action_rules.delete(DummyAuthController) }

    context "when action is missing" do
      before { Rabarber::Core::Permissions.add(DummyAuthController, :index, [:admin], nil, nil, nil) }

      it "raises error" do
        expect { subject }.to raise_error(Rabarber::Error, "The following actions were passed to `grant_access` but are not defined in the controller:\n---\n- !ruby/class 'DummyAuthController':\n  - :index\n")
      end
    end

    context "when action is not missing" do
      it "does not raise error" do
        expect { subject }.not_to raise_error
      end
    end
  end
end
