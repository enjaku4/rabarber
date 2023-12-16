# frozen_string_literal: true

RSpec.describe Rabarber::Authorization do
  let(:user) { User.create! }

  shared_examples_for "it allows access" do |hash|
    it "allows access when request format is html" do
      send(hash.keys.first, hash.values.first, params: hash[:params])
      expect(response).to have_http_status(:success)
    end

    it "allows access when request format is not html" do
      send(hash.keys.first, hash.values.first, format: :js, params: hash[:params])
      expect(response).to have_http_status(:success)
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
  end

  shared_examples_for "it does not allow access when user must have roles" do |hash|
    before { Rabarber::Configuration.instance.must_have_roles = true }

    it_behaves_like "it does not allow access", hash
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

      context "when the user does not have a role" do
        it_behaves_like "it does not allow access", get: :multiple_roles
      end

      it_behaves_like "it does not allow access when user must have roles", get: :multiple_roles
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

      context "when the user does not have a role" do
        it_behaves_like "it does not allow access", post: :single_role
      end

      it_behaves_like "it does not allow access when user must have roles", post: :single_role
    end

    describe "when everyone is allowed" do
      context "when the user has a role" do
        before { user.assign_roles(:admin) }

        it_behaves_like "it allows access", put: :all_access
      end

      context "when the user does not have a role" do
        it_behaves_like "it allows access", put: :all_access
      end

      it_behaves_like "it does not allow access when user must have roles", put: :all_access
    end

    describe "when no one is allowed" do
      context "when the user has a role" do
        before { user.assign_roles(:admin) }

        it_behaves_like "it does not allow access", delete: :no_access
      end

      context "when the user does not have a role" do
        it_behaves_like "it does not allow access", delete: :no_access
      end

      it_behaves_like "it does not allow access when user must have roles", delete: :no_access
    end

    describe "when a custom rule is defined as a lambda" do
      context "when the lambda returns true" do
        before { user.assign_roles(:admin) }

        it_behaves_like "it allows access", get: :if_lambda, params: { foo: "bar" }
      end

      context "when the lambda returns false" do
        before { user.assign_roles(:admin) }

        it_behaves_like "it does not allow access", get: :if_lambda, params: { foo: "baz" }
      end

      it_behaves_like "it does not allow access when user must have roles", get: :if_lambda, params: { foo: "bar" }
    end

    describe "when a custom rule is defined as a method" do
      context "when the method returns true" do
        before { user.assign_roles(:admin) }

        it_behaves_like "it allows access", post: :if_method, params: { bad: "baz" }
      end

      context "when the method returns false" do
        before { user.assign_roles(:admin) }

        it_behaves_like "it does not allow access", post: :if_method, params: { bad: "bar" }
      end

      it_behaves_like "it does not allow access when user must have roles", post: :if_method, params: { bad: "baz" }
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

      it_behaves_like "it does not allow access when user must have roles", put: :foo
      it_behaves_like "it does not allow access when user must have roles", delete: :bar
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

      context "when the user's role does not allow access" do
        before { user.assign_roles(:admin) }

        it_behaves_like "it does not allow access", post: :baz
        it_behaves_like "it does not allow access", patch: :bad
      end

      it_behaves_like "it does not allow access when user must have roles", post: :baz
      it_behaves_like "it does not allow access when user must have roles", patch: :bad
    end
  end
end
