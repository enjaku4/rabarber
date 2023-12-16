# frozen_string_literal: true

RSpec.describe Rabarber::Helpers do
  let(:dummy_helper) { DummyHelper.new(nil, {}, nil) }

  before { allow(dummy_helper).to receive(:current_user).and_return(user) }

  describe "#visible_to" do
    subject { dummy_helper.visible_to(:manager, :accountant) { "foo" } }

    let(:user) { User.create! }

    context "when the user has one of the given roles" do
      before { user.assign_roles(:admin, :client, :accountant) }

      it { is_expected.to eq("foo") }
    end

    context "when the user does not have any of the given roles" do
      before { user.assign_roles(:admin, :client) }

      it { is_expected.to be_nil }
    end
  end

  describe "#hidden_from" do
    subject { dummy_helper.hidden_from(:manager, :accountant) { "foo" } }

    let(:user) { User.create! }

    context "when the user has one of the given roles" do
      before { user.assign_roles(:admin, :client, :accountant) }

      it { is_expected.to be_nil }
    end

    context "when the user does not have any of the given roles" do
      before { user.assign_roles(:admin, :client) }

      it { is_expected.to eq("foo") }
    end
  end
end
