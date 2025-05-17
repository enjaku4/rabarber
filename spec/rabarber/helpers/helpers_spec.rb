# frozen_string_literal: true

RSpec.describe Rabarber::Helpers do
  let(:dummy_helper) { DummyHelper.new(nil, {}, nil) }

  before { allow(dummy_helper).to receive(:current_user).and_return(user) }

  describe "#visible_to" do
    subject { dummy_helper.visible_to(*roles, context:) { "foo" } }

    let(:user) { User.create! }
    let(:roles) { [:manager, :accountant] }
    let(:context) { Project }

    context "when there is no current user" do
      let(:user) { nil }

      it "raise an error" do
        expect { subject }.to raise_error(Rabarber::Error, "Expected `current_user` to return an instance of User, but got nil")
      end
    end

    context "when some of the roles are invalid" do
      let(:roles) { [:manager, :Admin] }

      it "raises an error" do
        expect { subject }.to raise_error(Rabarber::InvalidArgumentError, "Role names must be Symbols or Strings and may only contain lowercase letters, numbers, and underscores")
      end
    end

    context "when the user has one of the given roles" do
      before { user.assign_roles(:admin, :client, :accountant, context: Project) }

      it { is_expected.to eq("foo") }
    end

    context "when the user does not have any of the given roles" do
      before { user.assign_roles(:admin, :client, context: Project) }

      it { is_expected.to be_nil }
    end

    context "when the user has roles with the same name in different context" do
      before { user.assign_roles(:manager, :accountant, context: Project.create!) }

      it { is_expected.to be_nil }
    end
  end

  describe "#hidden_from" do
    subject { dummy_helper.hidden_from(*roles, context:) { "foo" } }

    let(:user) { User.create! }
    let(:roles) { [:manager, :accountant] }
    let(:context) { nil }

    context "when there is no current user" do
      let(:user) { nil }

      it "raise an error" do
        expect { subject }.to raise_error(Rabarber::Error, "Expected `current_user` to return an instance of User, but got nil")
      end
    end

    context "when some of the roles are invalid" do
      let(:roles) { [:manager, :Admin] }

      it "raises an error" do
        expect { subject }.to raise_error(Rabarber::InvalidArgumentError, "Role names must be Symbols or Strings and may only contain lowercase letters, numbers, and underscores")
      end
    end

    context "when the user has one of the given roles" do
      before { user.assign_roles(:admin, :client, :accountant) }

      it { is_expected.to be_nil }
    end

    context "when the user does not have any of the given roles" do
      before { user.assign_roles(:admin, :client) }

      it { is_expected.to eq("foo") }
    end

    context "when the user has roles with the same name in different context" do
      before { user.assign_roles(:manager, :accountant, context: Project.create!) }

      it { is_expected.to eq("foo") }
    end
  end
end
