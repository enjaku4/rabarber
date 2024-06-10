# frozen_string_literal: true

RSpec.describe Rabarber::Core::Roleable do
  let(:user) { User.create! }

  before { allow_any_instance_of(DummyController).to receive(:current_user).and_return(user) }

  describe "#roleable" do
    subject { DummyController.new.roleable }

    it { is_expected.to eq(user) }
  end

  describe "#roleable_roles" do
    subject { DummyController.new.roleable_roles }

    context "when user exists" do
      before do
        user.assign_roles(:admin)
        user.assign_roles(:manager, context: Project)
        user.assign_roles(:client, context: Project.create!)
      end

      it { is_expected.to match_array(Rabarber::Role.all) }
    end

    context "when user does not exist" do
      let(:user) { nil }

      it { is_expected.to be_empty }
    end
  end
end
