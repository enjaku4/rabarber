# frozen_string_literal: true

require_relative "shared_examples"

RSpec.describe NoUserController, type: :controller do
  before { allow(controller).to receive(:current_user).and_return(nil) }

  describe "when a role is allowed" do
    it_behaves_like "it does not allow access", put: :access_with_roles
  end

  describe "when everyone is allowed" do
    it_behaves_like "it allows access", get: :all_access
  end

  describe "when no one is allowed" do
    it_behaves_like "it does not allow access", post: :no_access
  end

  it_behaves_like "it checks permissions integrity", put: :access_with_roles
  it_behaves_like "it checks permissions integrity", get: :all_access
  it_behaves_like "it checks permissions integrity", post: :no_access
end
