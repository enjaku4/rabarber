# frozen_string_literal: true

require_relative "shared_examples"

RSpec.describe DummyChildController, type: :controller do
  let(:user) { User.create! }

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
  end
end
