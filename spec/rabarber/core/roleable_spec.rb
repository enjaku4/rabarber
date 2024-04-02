# frozen_string_literal: true

RSpec.describe Rabarber::Core::Roleable do
  let(:dummy_class) do
    Class.new do
      include Rabarber::Core::Roleable

      def current_user; end
    end
  end

  let(:user) { User.create! }

  before { allow_any_instance_of(dummy_class).to receive(:current_user).and_return(user) }

  describe "#roleable" do
    subject { dummy_class.new.roleable }

    it { is_expected.to eq(user) }
  end

  describe "#roleable_roles" do
    subject { dummy_class.new.roleable_roles }

    context "when user exists" do
      before { user.assign_roles(:admin, :manager) }

      it { is_expected.to contain_exactly(:admin, :manager) }
    end

    context "when user does not exist" do
      let(:user) { nil }

      it { is_expected.to be_empty }
    end
  end
end
