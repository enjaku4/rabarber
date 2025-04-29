# frozen_string_literal: true

RSpec.describe Rabarber::Core::IntegrityChecker do
  subject { described_class.new(controller).run! }

  after { Rabarber::Core::Permissions.action_rules.delete(DummyAuthController) }

  context "when controller is not specified" do
    let(:controller) { nil }

    context "when action is missing" do
      before { Rabarber::Core::Permissions.add(DummyAuthController, :index, [:admin], nil, nil, nil) }

      it "raises error" do
        expect { subject }.to raise_error(Rabarber::Error, "Following actions were passed to 'grant_access' method but are not defined in the controller:\n---\n- !ruby/class 'DummyAuthController':\n  - :index\n")
      end
    end

    context "when action is not missing" do
      it "does not raise error" do
        expect { subject }.not_to raise_error
      end
    end
  end

  context "when controller is specified" do
    let(:controller) { DummyAuthController }

    context "when action is missing" do
      before do
        Rabarber::Core::Permissions.add(DummyAuthController, :index, [:admin], Project, nil, nil)
        Rabarber::Core::Permissions.add(DummyAuthController, :show, [], Project.create!, nil, nil)
      end

      it "raises error" do
        expect { subject }.to raise_error(Rabarber::Error, "Following actions were passed to 'grant_access' method but are not defined in the controller:\n---\n- !ruby/class 'DummyAuthController':\n  - :index\n  - :show\n")
      end
    end

    context "when action is not missing" do
      it "does not raise error" do
        expect { subject }.not_to raise_error
      end
    end
  end
end
