# frozen_string_literal: true

RSpec.describe Rabarber::Input::Roles do
  describe "#process" do
    subject { described_class.new(roles).process }

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
            expect { subject }.to raise_error(
              Rabarber::InvalidArgumentError,
              "Expected an array of symbols or strings containing only lowercase letters, numbers, and underscores, got #{Array(invalid_role).inspect}"
            )
          end
        end
      end
    end
  end
end
