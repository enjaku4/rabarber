# frozen_string_literal: true

require_relative "shared_examples"

RSpec.describe AllAccessController, type: :controller do
  let(:user) { User.create! }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe "when everyone is allowed" do
    context "when the user has a role" do
      before { user.assign_roles(:maintainer) }

      it_behaves_like "it allows access", get: :quux
    end

    context "when the user has no roles" do
      it_behaves_like "it allows access", get: :quux
    end

    it_behaves_like "it checks permissions integrity", get: :quux
  end
end
