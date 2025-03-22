# frozen_string_literal: true

require_relative "shared_examples"

RSpec.describe ApiController, type: :controller do
  let(:user) { User.create! }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe "it works with ActionController::API" do
    context "when the user's role allows access" do
      before { user.assign_roles(:client) }

      it_behaves_like "it allows access", get: :api_action
    end

    context "when the user's role does not allow access" do
      before { user.assign_roles(:admin) }

      it_behaves_like "it does not allow access", get: :api_action
    end

    it_behaves_like "it checks permissions integrity", get: :api_action
  end
end
