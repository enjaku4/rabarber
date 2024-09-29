# frozen_string_literal: true

RSpec.describe Rabarber::Core::NullRoleable do
  let(:null_roleable) { described_class.new }

  describe "#roles" do
    subject { null_roleable.roles(context: "whatever") }

    it { is_expected.to be_empty }
  end

  describe "#log_identity" do
    subject { null_roleable.log_identity }

    it { is_expected.to eq("Unauthenticated user") }
  end
end
