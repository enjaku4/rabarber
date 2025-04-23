# frozen_string_literal: true

RSpec.describe Rabarber::Authorization do
  describe ".skip_authorization" do
    it "passes the options to skip_before_action" do
      expect(DummyAuthController).to receive(:skip_before_action).with(:authorize, only: [:index, :show], if: :foo?)
      DummyAuthController.skip_authorization(only: [:index, :show], if: :foo?)
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

      it_behaves_like "raises an error", Rabarber::InvalidArgumentError, "Action name must be a Symbol or a String"
    end

    context "when roles are invalid" do
      let(:args) { { roles: "junior developer" } }

      it_behaves_like "raises an error", Rabarber::InvalidArgumentError, "Role names must be Symbols or Strings and may only contain lowercase letters, numbers, and underscores"
    end

    context "when context is invalid" do
      let(:args) { { context: 1 } }

      it_behaves_like "raises an error", Rabarber::InvalidArgumentError, "Context must be a Class, an instance of ActiveRecord model, a Symbol, a String, or a Proc"
    end

    context "when dynamic rule is invalid" do
      let(:args) { { if: 1 } }

      it_behaves_like "raises an error", Rabarber::InvalidArgumentError, "Dynamic rule must be a Symbol, a String, or a Proc"
    end

    context "when negated dynamic rule is invalid" do
      let(:args) { { unless: 1 } }

      it_behaves_like "raises an error", Rabarber::InvalidArgumentError, "Dynamic rule must be a Symbol, a String, or a Proc"
    end

    context "when everything is valid" do
      let(:args) { { action: :index, roles: :admin, context: nil, if: :foo, unless: :bar } }

      it "adds the permission" do
        expect(Rabarber::Core::Permissions).to receive(:add)
          .with(DummyAuthController, :index, [:admin], { context_id: nil, context_type: nil }, :foo, :bar).and_call_original
        subject
      end

      it "uses Inputs to process the arguments" do
        { index: :Action, admin: :Roles, nil => :AuthorizationContext, foo: :DynamicRule, bar: :DynamicRule }.each do |arg, type|
          input_processor = instance_double(Rabarber::Input.const_get(type))
          allow(Rabarber::Input.const_get(type)).to receive(:new).with(arg).and_return(input_processor)
          expect(input_processor).to receive(:process)
        end
        subject
      end
    end
  end
end
