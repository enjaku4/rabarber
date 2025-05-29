# frozen_string_literal: true

require_relative "shared_examples"

RSpec.describe DummyController, type: :controller do
  let(:user) { User.create! }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe "when multiple roles are allowed" do
    context "when one user's role allows access" do
      before { user.assign_roles(:superadmin) }

      it_behaves_like "it allows access", get: :multiple_roles
    end

    context "when the other user's role allows access" do
      before { user.assign_roles(:admin) }

      it_behaves_like "it allows access", get: :multiple_roles
    end

    context "when no user's role allows access" do
      before { user.assign_roles(:manager) }

      it_behaves_like "it does not allow access", get: :multiple_roles
    end

    context "when the user does not have any roles" do
      it_behaves_like "it does not allow access", get: :multiple_roles
    end
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

    context "when the user does not have any roles" do
      it_behaves_like "it does not allow access", post: :single_role
    end
  end

  describe "when everyone is allowed" do
    context "when the user has a role" do
      before { user.assign_roles(:admin) }

      it_behaves_like "it allows access", put: :all_access
    end

    context "when the user does not have any roles" do
      it_behaves_like "it allows access", put: :all_access
    end
  end

  describe "when no one is allowed" do
    context "when the user has a role" do
      before { user.assign_roles(:admin) }

      it_behaves_like "it does not allow access", delete: :no_access
    end

    context "when the user does not have any roles" do
      it_behaves_like "it does not allow access", delete: :no_access
    end
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
    end
  end
end
