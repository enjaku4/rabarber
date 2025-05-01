# frozen_string_literal: true

RSpec.describe Rabarber::Input::ArModel do
  describe "#process" do
    subject { described_class.new(value, Rabarber::Error, "Error").process }

    context "when the given value is valid" do
      ["User", "Project"].each do |valid_value|
        context "when #{valid_value} is given" do
          let(:value) { valid_value }
          let(:expected_value) { valid_value.constantize }

          it { is_expected.to be expected_value }
        end
      end
    end

    context "when the given value is invalid" do
      [true, User, :user, 1, nil, [User], "user"].each do |invalid_value|
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
