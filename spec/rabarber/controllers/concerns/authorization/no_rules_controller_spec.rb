# frozen_string_literal: true

require_relative "shared_examples"

RSpec.describe NoRulesController, type: :controller do
  let(:user) { User.create! }

  before { allow(controller).to receive(:current_user).and_return(user) }

  context "when the user has a role" do
    before { user.assign_roles(:admin) }

    it_behaves_like "it does not allow access", delete: :no_rules
  end

  context "when the user does not have any roles" do
    it_behaves_like "it does not allow access", delete: :no_rules
  end
end
