# frozen_string_literal: true

RSpec.describe Rabarber::Core::Roleable do
  let(:user) { User.create! }

  before { allow_any_instance_of(DummyController).to receive(:current_user).and_return(user) }

  describe "#roleable" do
    subject { DummyController.new.roleable }

    it { is_expected.to eq(user) }
  end

  describe "#roleable_roles" do
    subject { DummyController.new.roleable_roles(context: Project) }

    context "when user exists" do
      before { user.assign_roles(:admin, :manager, context: Project) }

      it { is_expected.to contain_exactly(:admin, :manager) }
    end

    context "when user exists and has no such roles" do
      before { user.assign_roles(:admin, :manager, context: nil) }

      it { is_expected.to be_empty }
    end

    context "when user does not exist" do
      let(:user) { nil }

      it { is_expected.to be_empty }
    end
  end
end
