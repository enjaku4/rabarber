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

    describe "format of name" do
      ["admin 1", "admin!", "super-admin", "Admin"].each do |role_name|
        context "when role name is '#{role_name}'" do
          let(:role) { described_class.create(name: role_name) }

          it { is_expected.to be_invalid }

          it "has the 'name is invalid' error" do
            expect(role.errors.added?(:name, :invalid, value: role_name)).to be true
          end
        end
      end
    end
  end

  describe "callbacks" do
    describe "after_create" do
      it "deletes the cache" do
        expect(Rabarber::Cache).to receive(:delete).with(Rabarber::Cache::ALL_ROLES_KEY).and_call_original
        described_class.create!(name: "admin")
      end
    end

    describe "after_update" do
      let(:role) { described_class.create!(name: "admin") }

      it "deletes the cache" do
        expect(Rabarber::Cache).to receive(:delete).with(Rabarber::Cache::ALL_ROLES_KEY).twice.and_call_original
        role.update!(name: "developer")
      end
    end

    describe "after_destroy" do
      let(:role) { described_class.create!(name: "admin") }

      it "deletes the cache" do
        expect(Rabarber::Cache).to receive(:delete).with(Rabarber::Cache::ALL_ROLES_KEY).twice.and_call_original
        role.destroy!
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

  describe ".delete" do
    subject { described_class.delete(:admin) }

    context "when the role exists" do
      let!(:role) { described_class.create!(name: "admin") }

      context "when the role is not assigned to any user" do
        it "deletes the role" do
          expect { subject }.to change { described_class.find_by(name: "admin") }.from(role).to(nil)
        end
      end

      context "when the role is assigned to some users" do
        before { User.create!.assign_roles(:admin) }

        it "deletes the role" do
          expect { subject }.to change { described_class.find_by(name: "admin") }.from(role).to(nil)
        end
      end
    end

    context "when the role does not exist" do
      before { described_class.create!(name: "manager") }

      it "does nothing" do
        expect { subject }.not_to change(described_class, :count).from(1)
      end
    end
  end
end
