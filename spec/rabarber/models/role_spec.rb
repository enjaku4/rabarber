# frozen_string_literal: true

RSpec.describe Rabarber::Role do
  describe "validations" do
    subject { role }

    describe "presence of name" do
      let(:role) { described_class.create(name: "") }

      it { is_expected.to be_invalid }

      it "has the 'name can't be blank' error" do
        expect(role.errors.added?(:name, :blank)).to be true
      end
    end

    describe "uniqueness of name" do
      let(:role) { described_class.create(name: "admin") }

      before { described_class.create(name: "admin") }

      it { is_expected.to be_invalid }

      it "has the 'name has already been taken' error" do
        expect(role.errors.added?(:name, :taken, value: "admin")).to be true
      end
    end
  end

  describe ".names" do
    subject { described_class.names }

    context "when there are no roles" do
      it { is_expected.to eq([]) }
    end

    context "when there are some roles" do
      let(:role_names) { [:admin, :accountant, :manager] }

      before do
        role_names.each do |role_name|
          described_class.create!(name: role_name)
        end
      end

      it "returns an array of role names" do
        expect(subject).to match_array(role_names)
      end
    end
  end
end
