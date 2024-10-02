# frozen_string_literal: true

require_relative "shared_examples"

RSpec.describe ContextController, type: :controller do
  let(:user) { User.create! }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe "when context is global" do
    context "when the user's role allows access" do
      before { user.assign_roles(:admin) }

      it_behaves_like "it allows access", get: :global_ctx
    end

    context "when the user's role does not allow access" do
      before { user.assign_roles(:admin, context: Project) }

      it_behaves_like "it does not allow access", get: :global_ctx
    end

    it_behaves_like "it does not allow access when user must have roles", get: :global_ctx
    it_behaves_like "it checks permissions integrity", get: :global_ctx
  end

  describe "when context is a class" do
    context "when the user's role allows access" do
      before { user.assign_roles(:admin, context: Project) }

      it_behaves_like "it allows access", post: :class_ctx
    end

    context "when the user's role does not allow access" do
      before { user.assign_roles(:admin) }

      it_behaves_like "it does not allow access", post: :class_ctx
    end

    it_behaves_like "it does not allow access when user must have roles", post: :class_ctx
    it_behaves_like "it checks permissions integrity", post: :class_ctx
  end

  describe "when context is an instance" do
    context "when the user's role allows access" do
      before do
        project = Project.create!
        allow(Project).to receive(:create!).and_return(project)
        user.assign_roles(:admin, context: project)
      end

      it_behaves_like "it allows access", put: :instance_ctx
    end

    context "when the user's role does not allow access" do
      before { user.assign_roles(:admin, context: Project) }

      it_behaves_like "it does not allow access", put: :instance_ctx
    end

    it_behaves_like "it does not allow access when user must have roles", put: :instance_ctx
    it_behaves_like "it checks permissions integrity", put: :instance_ctx
  end

  context "when context is a symbol" do
    context "when the user's role allows access" do
      before do
        project = Project.create!
        allow(Project).to receive(:create!).and_return(project)
        user.assign_roles(:admin, context: project)
      end

      it_behaves_like "it allows access", patch: :symbol_ctx
    end

    context "when the user's role does not allow access" do
      before { user.assign_roles(:admin) }

      it_behaves_like "it does not allow access", patch: :symbol_ctx
    end

    it_behaves_like "it does not allow access when user must have roles", patch: :symbol_ctx
    it_behaves_like "it checks permissions integrity", patch: :symbol_ctx
  end

  context "when context is a proc" do
    context "when the user's role allows access" do
      before { user.assign_roles(:admin, context: Project) }

      it_behaves_like "it allows access", delete: :proc_ctx
    end

    context "when the user's role does not allow access" do
      before { user.assign_roles(:admin, context: Project.create!) }

      it_behaves_like "it does not allow access", delete: :proc_ctx
    end

    it_behaves_like "it does not allow access when user must have roles", delete: :proc_ctx
    it_behaves_like "it checks permissions integrity", delete: :proc_ctx
  end
end
