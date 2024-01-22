# frozen_string_literal: true

RSpec.describe Rabarber::Input::Types::Booleans do
  describe "#process" do
    subject { described_class.new(value, Rabarber::Error, "Error").process }

    context "when the given value is valid" do
      context "when true is given" do
        let(:value) { true }

        it { is_expected.to be true }
      end

      context "when false is given" do
        let(:value) { false }

        it { is_expected.to be false }
      end
    end

    context "when the given value is invalid" do
      [nil, 1, "foo", :foo, [], {}, User].each do |invalid_value|
        let(:value) { invalid_value }

        it "raises an ArgumentError when '#{invalid_value}' is given" do
          expect { subject }.to raise_error(Rabarber::Error, "Error")
        end
      end
    end
  end
end
