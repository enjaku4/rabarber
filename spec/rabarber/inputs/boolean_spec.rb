# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rabarber::Inputs::Boolean do
  describe "#process" do
    subject { described_class.new(value, error: Rabarber::Error, message: "Error").process }

    context "when the given value is valid" do
      [true, false].each do |valid_value|
        context "when #{valid_value.inspect} is given" do
          let(:value) { valid_value }

          it { is_expected.to be valid_value }
        end
      end
    end

    context "when the given value is invalid" do
      [nil, 1, "foo", :foo, [], {}, User].each do |invalid_value|
        context "when '#{invalid_value.inspect}' is given" do
          let(:value) { invalid_value }

          it "raises an error" do
            expect { subject }.to raise_error(Rabarber::Error, "Error")
          end
        end
      end
    end
  end
end
