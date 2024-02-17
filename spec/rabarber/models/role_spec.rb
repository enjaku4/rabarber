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
    subject { described_class.delete(:admin, force: force) }

    shared_examples_for "it does nothing" do
      before { described_class.create!(name: "manager") }

      it "does nothing" do
        expect { subject }.not_to change(described_class, :count)
      end

      it { is_expected.to be false }

      it "does not clear the cache" do
        expect(Rabarber::Cache).not_to receive(:delete)
        subject
      end
    end

    shared_examples_for "it deletes the role" do |role_assigned: false|
      it "deletes the role" do
        expect { subject }.to change(described_class.where(name: "admin"), :count).from(1).to(0)
      end

      it { is_expected.to be true }

      it "clears the cache" do
        expect(Rabarber::Cache).to receive(:delete).with(Rabarber::Cache::ALL_ROLES_KEY)
        expect(Rabarber::Cache).to receive(:delete).with(Rabarber::Cache.key_for(user.id)) if role_assigned
        subject
      end
    end

    context "when the role does not exist" do
      context "when force is false" do
        let(:force) { false }

        it_behaves_like "it does nothing"
      end

      context "when force is true" do
        let(:force) { true }

        it_behaves_like "it does nothing"
      end
    end

    context "when the role exists" do
      before { described_class.create!(name: "admin") }

      context "when the role is not assigned to any user" do
        context "when force is false" do
          let(:force) { false }

          it_behaves_like "it deletes the role"
        end

        context "when force is true" do
          let(:force) { true }

          it_behaves_like "it deletes the role"
        end
      end

      context "when the role is assigned to some users" do
        let(:user) { User.create! }

        before { user.assign_roles(:admin) }

        context "when force is false" do
          let(:force) { false }

          it_behaves_like "it does nothing"
        end

        context "when force is true" do
          let(:force) { true }

          it_behaves_like "it deletes the role", role_assigned: true
        end
      end
    end
  end
end
