# frozen_string_literal: true

require_relative "shared_examples"

RSpec.describe MultipleRulesController, type: :controller do
  let(:user) { User.create! }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe "when multitple controller rules are applied" do
    context "when one of the user's roles allows access" do
      before { user.assign_roles(:maintainer) }

      it_behaves_like "it allows access", delete: :qux
    end

    context "when another one of the user's roles allows access" do
      before { user.assign_roles(:user, context: Project) }

      it_behaves_like "it allows access", delete: :qux
    end

    context "when the user's role does not allow access" do
      before { user.assign_roles(:admin) }

      it_behaves_like "it does not allow access", delete: :qux
    end

    context "when the user does not have any roles" do
      it_behaves_like "it does not allow access", delete: :qux
    end
  end
end
