# frozen_string_literal: true

RSpec.describe Rabarber::Input::Role do
  describe "#process" do
    subject { described_class.new(role).process }

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
        let(:role) { invalid_role }

        it "raises an error when '#{invalid_role}' is given as a role name" do
          expect { subject }.to raise_error(
            Rabarber::InvalidArgumentError,
            "Role name must be a Symbol or a String and may only contain lowercase letters, numbers and underscores"
          )
        end
      end
    end
  end
end
