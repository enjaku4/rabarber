# frozen_string_literal: true

RSpec.describe Rabarber::Core::IntegrityChecker do
  subject { described_class.run! }

  context "checking missing class context" do
    context "when class is missing in class context" do
      before { Rabarber::Role.create!(name: "manager", context_type: "Order", context_id: nil) }

      it "raises error" do
        expect { subject }.to raise_error(Rabarber::Error, "Context not found: class Order may have been renamed or deleted")
      end
    end

    context "when class is mising in instance context" do
      before { Rabarber::Role.create!(name: "manager", context_type: "Order", context_id: 1) }

      it "raises error" do
        expect { subject }.to raise_error(Rabarber::Error, "Context not found: class Order may have been renamed or deleted")
      end
    end

    context "when class is not missing" do
      before do
        project = Project.create!
        Rabarber::Role.create!(name: "manager", context_type: "Project", context_id: nil)
        Rabarber::Role.create!(name: "viewer", context_type: "Project", context_id: project.id)
        Rabarber::Role.create!(name: "admin", context_type: nil, context_id: nil)
      end

      it "does not raise error" do
        expect { subject }.not_to raise_error
      end
    end
  end

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
