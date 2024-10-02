# frozen_string_literal: true

require_relative "shared_examples"

describe SkipAuthorizationController, type: :controller do
  let(:user) { User.create! }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe "when action is skipped and no rules are applied" do
    it_behaves_like "it allows access", get: :skip_no_rules

    it_behaves_like "it allows access even when user must have roles", get: :skip_no_rules
    it_behaves_like "it does not check permissions integrity whatsoever", get: :skip_no_rules
  end

  describe "when action is skipped and rules are applied" do
    it_behaves_like "it allows access", put: :skip_rules

    it_behaves_like "it allows access even when user must have roles", put: :skip_rules
    it_behaves_like "it does not check permissions integrity whatsoever", put: :skip_rules
  end

  describe "when action is not skipped" do
    it_behaves_like "it does not allow access", post: :no_skip

    it_behaves_like "it does not allow access when user must have roles", post: :no_skip
    it_behaves_like "it checks permissions integrity", post: :no_skip
  end
end
