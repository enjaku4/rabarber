# frozen_string_literal: true

RSpec.describe Rabarber::Authorization do
  describe ".with_authorization" do
    it "passes the options to before_action" do
      expect(DummyAuthController).to receive(:before_action).with(:with_authorization, only: [:index, :show], if: :foo?)
      DummyAuthController.with_authorization(only: [:index, :show], if: :foo?)
    end

    context "when ArgumentError is raised" do
      before do
        allow(DummyAuthController).to receive(:before_action).and_raise(ArgumentError, "No before_action found")
      end

      it "re-raises the error" do
        expect { DummyAuthController.with_authorization(only: [:index, :show], if: :foo?) }
          .to raise_error(Rabarber::InvalidArgumentError, "No before_action found")
      end
    end
  end

  describe ".skip_authorization" do
    it "passes the options to skip_before_action" do
      expect(DummyAuthController).to receive(:skip_before_action).with(:with_authorization, only: [:index, :show], if: :foo?)
      DummyAuthController.skip_authorization(only: [:index, :show], if: :foo?)
    end

    context "when ArgumentError is raised" do
      before do
        allow(DummyAuthController).to receive(:skip_before_action).and_raise(ArgumentError, "No before_action found")
      end

      it "re-raises the error" do
        expect { DummyAuthController.skip_authorization(only: [:index, :show], if: :foo?) }
          .to raise_error(Rabarber::InvalidArgumentError, "No before_action found")
      end
    end
  end

  describe ".grant_access" do
    subject { DummyAuthController.grant_access(**args) }

    after { Rabarber::Core::Permissions.action_rules.delete(DummyAuthController) }

    shared_examples_for "raises an error" do |error_class, error_message|
      it "raises an error" do
        expect { subject }.to raise_error(error_class, error_message)
      end
    end

    context "when action is invalid" do
      let(:args) { { action: 1 } }

      it_behaves_like "raises an error", Rabarber::InvalidArgumentError, /undefined method `to_sym' for.+Integer/
    end

    context "when roles are invalid" do
      let(:args) { { roles: "junior developer" } }

      it_behaves_like "raises an error", Rabarber::InvalidArgumentError, "Expected an array of symbols or strings containing only lowercase letters, numbers, and underscores, got \"junior developer\""
    end

    context "when context is invalid" do
      let(:args) { { context: 1 } }

      it_behaves_like "raises an error", Rabarber::InvalidArgumentError, "Expected a Class, an instance of ActiveRecord model, a symbol, a string, or a proc, got 1"
    end

    context "when dynamic rule is invalid" do
      let(:args) { { if: 1 } }

      it_behaves_like "raises an error", Rabarber::InvalidArgumentError, "Expected a symbol, a string, or a proc, got 1"
    end

    context "when negated dynamic rule is invalid" do
      let(:args) { { unless: 1 } }

      it_behaves_like "raises an error", Rabarber::InvalidArgumentError, "Expected a symbol, a string, or a proc, got 1"
    end

    context "when everything is valid" do
      let(:args) { { action: :index, roles: :admin, context: nil, if: :foo, unless: :bar } }

      it "adds the permission" do
        expect(Rabarber::Core::Permissions).to receive(:add)
          .with(DummyAuthController, :index, [:admin], { context_id: nil, context_type: nil }, :foo, :bar).and_call_original
        subject
      end
    end
  end
end
