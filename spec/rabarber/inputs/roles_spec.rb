# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rabarber::Inputs::Roles do
  describe "#process" do
    subject { described_class.new(roles, error: Rabarber::InvalidArgumentError, message: "Error").process }

    context "when the given roles are valid" do
      context "when an array of roles is given" do
        let(:roles) { [:admin, "manager"] }

        it { is_expected.to contain_exactly(:admin, :manager) }
      end

      context "when a single role is given" do
        let(:roles) { :admin }

        it { is_expected.to contain_exactly(:admin) }
      end

      context "when nil is given" do
        let(:roles) { nil }

        it { is_expected.to eq([]) }
      end
    end

    context "when the given role is invalid" do
      [1, [""], Symbol, :"a-user", :Admin, "Admin", "admin ", { manager: true }].each do |invalid_role|
        context "when '#{invalid_role}' is given" do
          let(:roles) { invalid_role }

          it "raises an error" do
            expect { subject }.to raise_error(Rabarber::InvalidArgumentError, "Error")
          end
        end
      end
    end
  end
end
