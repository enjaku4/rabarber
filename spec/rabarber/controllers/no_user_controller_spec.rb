# frozen_string_literal: true

require_relative "shared_examples"

RSpec.describe NoUserController, type: :controller do
  before { allow(controller).to receive(:current_user).and_return(nil) }

  describe "when a role is allowed" do
    it_behaves_like "it raises an error on nil current_user", put: :access_with_roles
  end

  describe "when everyone is allowed" do
    it_behaves_like "it raises an error on nil current_user", get: :all_access
  end

  describe "when no one is allowed" do
    it_behaves_like "it raises an error on nil current_user", post: :no_access
  end
end
