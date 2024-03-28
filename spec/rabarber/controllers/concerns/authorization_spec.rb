# frozen_string_literal: true

RSpec.describe Rabarber::Authorization do
  let(:user) { User.create! }

  describe ".grant_access" do
    subject { DummyAuthController.grant_access(**args) }

    after { Rabarber::Core::Permissions.action_rules.delete(DummyAuthController) }

    context "when action is invalid" do
      let(:args) { { action: 1 } }

      it "raises an error" do
        expect { subject }.to raise_error(Rabarber::InvalidArgumentError, "Action name must be a Symbol or a String")
      end
    end

    context "when roles are invalid" do
      let(:args) { { roles: "junior developer" } }

      it "raises an error" do
        expect { subject }.to raise_error(
          Rabarber::InvalidArgumentError,
          "Role names must be Symbols or Strings and may only contain lowercase letters, numbers and underscores"
        )
      end
    end

    context "when dynamic rule is invalid" do
      let(:args) { { if: 1 } }

      it "raises an error" do
        expect { subject }.to raise_error(
          Rabarber::InvalidArgumentError,
          "Dynamic rule must be a Symbol, a String, or a Proc"
        )
      end
    end

    context "when negated dynamic rule is invalid" do
      let(:args) { { unless: 1 } }

      it "raises an error" do
        expect { subject }.to raise_error(
          Rabarber::InvalidArgumentError,
          "Dynamic rule must be a Symbol, a String, or a Proc"
        )
      end
    end

    context "when everything is valid" do
      let(:args) { { action: :index, roles: :admin, if: -> { true }, unless: -> { false } } }

      it "adds the permission" do
        expect(Rabarber::Core::Permissions).to receive(:add)
          .with(DummyAuthController, :index, [:admin], args[:if], args[:unless]).and_call_original
        subject
      end

      it "uses Input::Action to process the given action" do
        input_processor = instance_double(Rabarber::Input::Action, process: :index)
        allow(Rabarber::Input::Action).to receive(:new).with(:index).and_return(input_processor)
        expect(input_processor).to receive(:process).with(no_args)
        subject
      end

      it "uses Input::Roles to process the given roles" do
        input_processor = instance_double(Rabarber::Input::Roles, process: [:admin])
        allow(Rabarber::Input::Roles).to receive(:new).with(:admin).and_return(input_processor)
        expect(input_processor).to receive(:process).with(no_args)
        subject
      end

      it "uses Input::DynamicRule to process the given dynamic rules" do
        input_processor_foo = instance_double(Rabarber::Input::DynamicRule, process: :foo)
        input_processor_bar = instance_double(Rabarber::Input::DynamicRule, process: :bar)
        allow(Rabarber::Input::DynamicRule).to receive(:new).with(args[:if]).and_return(input_processor_foo)
        allow(Rabarber::Input::DynamicRule).to receive(:new).with(args[:unless]).and_return(input_processor_bar)
        expect(input_processor_foo).to receive(:process).with(no_args)
        expect(input_processor_bar).to receive(:process).with(no_args)
        subject
      end
    end

    context "when 'if' is specified" do
      let(:args) { { action: :foo, roles: :bar, if: -> { true } } }

      it "adds the permission" do
        expect(Rabarber::Core::Permissions).to receive(:add)
          .with(DummyAuthController, :foo, [:bar], args[:if], nil).and_call_original
        subject
      end
    end

    context "when 'unless' is specified" do
      let(:args) { { action: :foo, roles: :bar, unless: -> { false } } }

      it "adds the permission" do
        expect(Rabarber::Core::Permissions).to receive(:add)
          .with(DummyAuthController, :foo, [:bar], nil, args[:unless]).and_call_original
        subject
      end
    end

    context "when neither 'if' nor 'unless' is specified" do
      let(:args) { { action: :foo, roles: :bar } }

      it "adds the permission" do
        expect(Rabarber::Core::Permissions).to receive(:add)
          .with(DummyAuthController, :foo, [:bar], nil, nil).and_call_original
        subject
      end
    end

    context "when both 'if' and 'unless' are specified" do
      let(:args) { { action: :foo, roles: :bar, if: -> { true }, unless: -> { false } } }

      it "adds the permission" do
        expect(Rabarber::Core::Permissions).to receive(:add)
          .with(DummyAuthController, :foo, [:bar], args[:if], args[:unless]).and_call_original
        subject
      end
    end

    context "when action and roles are omitted" do
      let(:args) { {} }

      it "adds the permission" do
        expect(Rabarber::Core::Permissions).to receive(:add)
          .with(DummyAuthController, nil, [], nil, nil).and_call_original
        subject
      end
    end
  end

  shared_examples_for "it allows access" do |hash|
    it "allows access when request format is html" do
      send(hash.keys.first, hash.values.first, params: hash[:params])
      expect(response).to have_http_status(:success)
    end

    it "allows access when request format is not html" do
      send(hash.keys.first, hash.values.first, format: :js, params: hash[:params])
      expect(response).to have_http_status(:success)
    end

    it "does not log a warning to the audit trail" do
      expect(Rabarber::Logger).not_to receive(:audit)
      send(hash.keys.first, hash.values.first, params: hash[:params])
    end
  end

  shared_examples_for "it does not allow access" do |hash|
    it "does not allow access when request format is html" do
      send(hash.keys.first, hash.values.first, params: hash[:params])
      expect(response).to redirect_to(DummyApplication.routes.url_helpers.root_path)
    end

    it "does not allow access when request format is not html" do
      send(hash.keys.first, hash.values.first, format: :js, params: hash[:params])
      expect(response).to have_http_status(:unauthorized)
    end

    it "logs a warning to the audit trail" do
      expect(Rabarber::Audit::Events::UnauthorizedAttempt).to receive(:trigger)
        .with(controller.current_user, path: request.path).and_call_original
      send(hash.keys.first, hash.values.first, params: hash[:params])
    end
  end

  shared_examples_for "it does not allow access when user must have roles" do |hash|
    before { Rabarber::Configuration.instance.must_have_roles = true }

    it_behaves_like "it does not allow access", hash
  end

  shared_examples_for "it handles missing actions and roles" do |hash|
    context "when eager_load is false, table exists and logger is in debug mode" do
      before { allow(Rails.configuration).to receive(:eager_load).and_return(false) }

      it "handles missing actions and roles" do
        expect(Rabarber::Missing::Actions).to receive_message_chain(:new, :handle)
        expect(Rabarber::Missing::Roles).to receive_message_chain(:new, :handle)
        send(hash.keys.first, hash.values.first, params: hash[:params])
      end
    end

    context "when eager_load is true" do
      before { allow(Rails.configuration).to receive(:eager_load).and_return(true) }

      it "does not handle missing actions" do
        expect(Rabarber::Missing::Actions).not_to receive(:new)
        send(hash.keys.first, hash.values.first, params: hash[:params])
      end
    end

    context "when table does not exist" do
      before { allow(Rabarber::Role).to receive(:table_exists?).and_return(false) }

      it "does not handle missing roles" do
        expect(Rabarber::Missing::Roles).not_to receive(:new)
        send(hash.keys.first, hash.values.first, params: hash[:params])
      end
    end

    context "when logger is not in debug mode" do
      before { allow(Rails.logger).to receive(:debug?).and_return(false) }

      it "does not handle missing roles" do
        expect(Rabarber::Missing::Roles).not_to receive(:new)
        send(hash.keys.first, hash.values.first, params: hash[:params])
      end
    end
  end

  describe DummyController, type: :controller do
    before { allow(controller).to receive(:current_user).and_return(user) }

    describe "when multiple roles are allowed" do
      context "when at least one user's role allows access" do
        before { user.assign_roles(:superadmin) }

        it_behaves_like "it allows access", get: :multiple_roles
      end

      context "when no user's role allows access" do
        before { user.assign_roles(:manager) }

        it_behaves_like "it does not allow access", get: :multiple_roles
      end

      context "when the user has a different role" do
        before { user.assign_roles(:client) }

        it_behaves_like "it does not allow access", get: :multiple_roles
      end

      context "when the user does not have any roles" do
        it_behaves_like "it does not allow access", get: :multiple_roles
      end

      it_behaves_like "it does not allow access when user must have roles", get: :multiple_roles
      it_behaves_like "it handles missing actions and roles", get: :multiple_roles
    end

    describe "when a single role is allowed" do
      context "when the user's role allows access" do
        before { user.assign_roles(:client) }

        it_behaves_like "it allows access", post: :single_role
      end

      context "when the user's role does not allow access" do
        before { user.assign_roles(:admin) }

        it_behaves_like "it does not allow access", post: :single_role
      end

      context "when the user has a different role" do
        before { user.assign_roles(:manager) }

        it_behaves_like "it does not allow access", post: :single_role
      end

      context "when the user does not have any roles" do
        it_behaves_like "it does not allow access", post: :single_role
      end

      it_behaves_like "it does not allow access when user must have roles", post: :single_role
      it_behaves_like "it handles missing actions and roles", post: :single_role
    end

    describe "when everyone is allowed" do
      context "when the user has a role" do
        before { user.assign_roles(:admin) }

        it_behaves_like "it allows access", put: :all_access
      end

      context "when the user does not have any roles" do
        it_behaves_like "it allows access", put: :all_access
      end

      it_behaves_like "it does not allow access when user must have roles", put: :all_access
      it_behaves_like "it handles missing actions and roles", put: :all_access
    end

    describe "when no one is allowed" do
      context "when the user has a role" do
        before { user.assign_roles(:admin) }

        it_behaves_like "it does not allow access", delete: :no_access
      end

      context "when the user does not have any roles" do
        it_behaves_like "it does not allow access", delete: :no_access
      end

      it_behaves_like "it does not allow access when user must have roles", delete: :no_access
      it_behaves_like "it handles missing actions and roles", delete: :no_access
    end

    describe "when multiple rules applied" do
      context "when the user has one of the roles" do
        before { user.assign_roles(:manager) }

        it_behaves_like "it allows access", post: :multiple_rules
      end

      context "when the user has the other role" do
        before { user.assign_roles(:client) }

        it_behaves_like "it allows access", post: :multiple_rules
      end

      context "when the user has another role" do
        before { user.assign_roles(:admin) }

        it_behaves_like "it does not allow access", post: :multiple_rules
      end

      context "when the user does not have any roles" do
        it_behaves_like "it does not allow access", post: :multiple_rules
      end

      it_behaves_like "it does not allow access when user must have roles", post: :multiple_rules
      it_behaves_like "it handles missing actions and roles", post: :multiple_rules
    end

    context "when dynamic rule is not negated" do
      describe "when dynamic rule is defined as a lambda" do
        context "when the lambda returns true" do
          before { user.assign_roles(:admin) }

          it_behaves_like "it allows access", get: :if_lambda, params: { foo: "bar" }
        end

        context "when the lambda returns false" do
          before { user.assign_roles(:admin) }

          it_behaves_like "it does not allow access", get: :if_lambda, params: { foo: "baz" }
        end

        it_behaves_like "it does not allow access when user must have roles", get: :if_lambda, params: { foo: "bar" }
        it_behaves_like "it handles missing actions and roles", get: :if_lambda, params: { foo: "bar" }
      end

      describe "when dynamic rule is defined as a method" do
        context "when the method returns true" do
          before { user.assign_roles(:admin) }

          it_behaves_like "it allows access", post: :if_method, params: { bad: "baz" }
        end

        context "when the method returns false" do
          before { user.assign_roles(:admin) }

          it_behaves_like "it does not allow access", post: :if_method, params: { bad: "bar" }
        end

        it_behaves_like "it does not allow access when user must have roles", post: :if_method, params: { bad: "baz" }
        it_behaves_like "it handles missing actions and roles", post: :if_method, params: { bad: "baz" }
      end
    end

    context "when dynamic rule is negated" do
      describe "when dynamic rule is defined as a lambda" do
        context "when the lambda returns true" do
          before { user.assign_roles(:admin) }

          it_behaves_like "it does not allow access", patch: :unless_lambda, params: { foo: "bar" }
        end

        context "when the lambda returns false" do
          before { user.assign_roles(:admin) }

          it_behaves_like "it allows access", patch: :unless_lambda, params: { foo: "baz" }
        end

        it_behaves_like "it does not allow access when user must have roles",
                        patch: :unless_lambda, params: { foo: "bar" }
        it_behaves_like "it handles missing actions and roles",
                        patch: :unless_lambda, params: { foo: "bar" }
      end

      describe "when dynamic rule is defined as a method" do
        context "when the method returns true" do
          before { user.assign_roles(:admin) }

          it_behaves_like "it does not allow access", delete: :unless_method, params: { bad: "baz" }
        end

        context "when the method returns false" do
          before { user.assign_roles(:admin) }

          it_behaves_like "it allows access", delete: :unless_method, params: { bad: "bar" }
        end

        it_behaves_like "it does not allow access when user must have roles",
                        delete: :unless_method, params: { bad: "baz" }
        it_behaves_like "it handles missing actions and roles",
                        delete: :unless_method, params: { bad: "baz" }
      end
    end
  end

  describe DummyParentController, type: :controller do
    before { allow(controller).to receive(:current_user).and_return(user) }

    describe "when a controller rule is applied" do
      context "when the user's role allows access" do
        before { user.assign_roles(:manager) }

        it_behaves_like "it allows access", put: :foo
        it_behaves_like "it allows access", delete: :bar
      end

      context "when the user's role does not allow access" do
        before { user.assign_roles(:admin) }

        it_behaves_like "it does not allow access", put: :foo
        it_behaves_like "it does not allow access", delete: :bar
      end

      context "when the user does not have any roles" do
        it_behaves_like "it does not allow access", put: :foo
        it_behaves_like "it does not allow access", delete: :bar
      end

      it_behaves_like "it does not allow access when user must have roles", put: :foo
      it_behaves_like "it does not allow access when user must have roles", delete: :bar
      it_behaves_like "it handles missing actions and roles", put: :foo
      it_behaves_like "it handles missing actions and roles", delete: :bar
    end
  end

  describe DummyChildController, type: :controller do
    before { allow(controller).to receive(:current_user).and_return(user) }

    describe "when a controller rule is applied to the parent" do
      context "when the user's role allows access" do
        before { user.assign_roles(:manager) }

        it_behaves_like "it allows access", post: :baz
        it_behaves_like "it allows access", patch: :bad
      end

      context "when additional rule is applied to the child and the user's role allows access" do
        before { user.assign_roles(:client) }

        it_behaves_like "it allows access", post: :baz
        it_behaves_like "it allows access", patch: :bad
      end

      context "when the user's role does not allow access" do
        before { user.assign_roles(:admin) }

        it_behaves_like "it does not allow access", post: :baz
        it_behaves_like "it does not allow access", patch: :bad
      end

      context "when the user does not have any roles" do
        it_behaves_like "it does not allow access", post: :baz
        it_behaves_like "it does not allow access", patch: :bad
      end

      it_behaves_like "it does not allow access when user must have roles", post: :baz
      it_behaves_like "it does not allow access when user must have roles", patch: :bad
      it_behaves_like "it handles missing actions and roles", post: :baz
      it_behaves_like "it handles missing actions and roles", patch: :bad
    end
  end

  describe NoUserController, type: :controller do
    before { allow(controller).to receive(:current_user).and_return(nil) }

    describe "when a role is allowed" do
      it_behaves_like "it does not allow access", put: :access_with_roles

      it_behaves_like "it does not allow access when user must have roles", put: :access_with_roles
      it_behaves_like "it handles missing actions and roles", put: :access_with_roles
    end

    describe "when everyone is allowed" do
      it_behaves_like "it allows access", get: :all_access

      it_behaves_like "it does not allow access when user must have roles", get: :all_access
      it_behaves_like "it handles missing actions and roles", get: :all_access
    end

    describe "when no one is allowed" do
      it_behaves_like "it does not allow access", post: :no_access

      it_behaves_like "it does not allow access when user must have roles", post: :no_access
      it_behaves_like "it handles missing actions and roles", post: :no_access
    end
  end
end
