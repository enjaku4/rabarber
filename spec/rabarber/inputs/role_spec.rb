# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rabarber::Inputs::Role do
  describe "#process" do
    subject { described_class.new(role, error: Rabarber::InvalidArgumentError, message: "Error").process }

    context "when the given role is valid" do
      context "when a symbol is given" do
        let(:role) { :admin }

        it { is_expected.to eq(:admin) }
      end

      context "when a string is given" do
        let(:role) { "manager" }

        it { is_expected.to eq(:manager) }
      end
    end

    context "when the given role is invalid" do
      [nil, "", 1, [""], Symbol, :"a-user", :Admin, "Admin", "admin ", { manager: true }].each do |invalid_role|
        context "when '#{invalid_role}' is given" do
          let(:role) { invalid_role }

          it "raises an error" do
            expect { subject }.to raise_error(
              Rabarber::InvalidArgumentError,
              "Error"
            )
          end
        end
      end
    end
  end
end
