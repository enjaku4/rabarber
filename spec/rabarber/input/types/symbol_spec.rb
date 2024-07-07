# frozen_string_literal: true

RSpec.describe Rabarber::Input::Types::Symbol do
  describe "#process" do
    subject { described_class.new(value, Rabarber::Error, "Error").process }

    context "when the given value is valid" do
      context "when a string is given" do
        let(:value) { "foo" }

        it { is_expected.to eq(:foo) }
      end

      context "when a symbol is given" do
        let(:value) { :bar }

        it { is_expected.to eq(:bar) }
      end
    end

    context "when the given value is invalid" do
      [nil, 1, [], {}, User, "", :""].each do |invalid_value|
        context "when '#{invalid_value}' is given" do
          let(:value) { invalid_value }

          it "raises an error" do
            expect { subject }.to raise_error(Rabarber::Error, "Error")
          end
        end
      end
    end
  end
end
