# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rabarber::Inputs::Model do
  describe "#process" do
    subject { described_class.new(value, error: Rabarber::Error, message: "Error").process }

    context "when the given value is valid" do
      ["User", "Project"].each do |valid_value|
        context "when #{valid_value} is given" do
          let(:value) { valid_value }
          let(:expected_value) { valid_value.to_s.constantize }

          it { is_expected.to be expected_value }
        end
      end
    end

    context "when the given value is invalid" do
      [true, :user, 1, nil, [User], User, "user"].each do |invalid_value|
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
