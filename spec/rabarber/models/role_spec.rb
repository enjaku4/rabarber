# frozen_string_literal: true

RSpec.describe Rabarber::Role do
  describe "validations" do
    subject { role }

    describe "presence of name" do
      subject { described_class.create(name: "") }

      it "raises the 'name can't be blank' error" do
        expect { subject }.to raise_error(ActiveModel::StrictValidationFailed, "Name can't be blank")
      end
    end

    describe "uniqueness of name" do
      subject { described_class.create(name: "admin") }

      before { described_class.create(name: "admin") }

      it "raises the 'name has already been taken' error" do
        expect { subject }.to raise_error(ActiveModel::StrictValidationFailed, "Name has already been taken")
      end
    end

    describe "format of name" do
      ["admin 1", "admin!", "super-admin", "Admin"].each do |role_name|
        context "when role name is '#{role_name}'" do
          subject { described_class.create(name: role_name) }

          it "raises the 'name is invalid' error" do
            expect { subject }.to raise_error(ActiveModel::StrictValidationFailed, "Name is invalid")
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

  shared_examples_for "role name is processed" do |roles|
    it "uses Input::Role to process the given roles" do
      roles.each do |role|
        input_processor = instance_double(Rabarber::Input::Role, process: role)
        allow(Rabarber::Input::Role).to receive(:new).with(role).and_return(input_processor)
        expect(input_processor).to receive(:process).with(no_args)
      end
      subject
    end
  end

  describe ".add" do
    subject { described_class.add(:admin) }

    context "when the role does not exist" do
      it "creates the role" do
        expect { subject }.to change { described_class.where(name: "admin").count }.from(0).to(1)
      end

      it { is_expected.to be true }

      it_behaves_like "role name is processed", [:admin]
    end

    context "when the role exists" do
      before { described_class.create!(name: "admin") }

      it "does nothing" do
        expect { subject }.not_to change(described_class, :count)
      end

      it { is_expected.to be false }

      it_behaves_like "role name is processed", [:admin]
    end
  end

  describe ".rename" do
    subject { described_class.rename(:admin, :manager, force: force) }

    shared_examples_for "it does nothing" do |role_exists: true|
      if role_exists
        it "does nothing" do
          expect { subject }.not_to change(role, :name)
        end
      end

      it { is_expected.to be false }

      it "does not clear the cache" do
        expect(Rabarber::Cache).not_to receive(:delete)
        subject
      end

      it_behaves_like "role name is processed", [:admin, :manager]
    end

    shared_examples_for "it renames the role" do |role_assigned: false|
      it "renames the role" do
        expect { subject }.to change { role.reload.name }.from("admin").to("manager")
      end

      it { is_expected.to be true }

      it "clears the cache" do
        expect(Rabarber::Cache).to receive(:delete).with(user.id) if role_assigned
        subject
      end

      it_behaves_like "role name is processed", [:admin, :manager]
    end

    context "when the role does not exist" do
      context "when force is false" do
        let(:force) { false }

        context "when the new role name is already taken" do
          before { described_class.create!(name: "manager") }

          it_behaves_like "it does nothing", role_exists: false
        end

        context "when the new role name is not taken" do
          it_behaves_like "it does nothing", role_exists: false
        end
      end

      context "when force is true" do
        let(:force) { true }

        context "when the new role name is already taken" do
          before { described_class.create!(name: "manager") }

          it_behaves_like "it does nothing", role_exists: false
        end

        context "when the new role name is not taken" do
          it_behaves_like "it does nothing", role_exists: false
        end
      end
    end

    context "when the role exists" do
      let!(:role) { described_class.create!(name: "admin") } # rubocop:disable RSpec/LetSetup

      context "when the role is not assigned to any user" do
        context "when force is false" do
          let(:force) { false }

          context "when the new role name is already taken" do
            before { described_class.create!(name: "manager") }

            it_behaves_like "it does nothing"
          end

          context "when the new role name is not taken" do
            it_behaves_like "it renames the role"
          end
        end

        context "when force is true" do
          let(:force) { true }

          context "when the new role name is already taken" do
            before { described_class.create!(name: "manager") }

            it_behaves_like "it does nothing"
          end

          context "when the new role name is not taken" do
            it_behaves_like "it renames the role"
          end
        end
      end

      context "when the role is assigned to some users" do
        let(:user) { User.create! }

        before { user.assign_roles(:admin) }

        context "when force is false" do
          let(:force) { false }

          context "when the new role name is already taken" do
            before { described_class.create!(name: "manager") }

            it_behaves_like "it does nothing"
          end

          context "when the new role name is not taken" do
            it_behaves_like "it does nothing"
          end
        end

        context "when force is true" do
          let(:force) { true }

          context "when the new role name is already taken" do
            before { described_class.create!(name: "manager") }

            it_behaves_like "it does nothing"
          end

          context "when the new role name is not taken" do
            it_behaves_like "it renames the role", role_assigned: true
          end
        end
      end
    end
  end

  describe ".remove" do
    subject { described_class.remove(:admin, force: force) }

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

      it_behaves_like "role name is processed", [:admin]
    end

    shared_examples_for "it deletes the role" do |role_assigned: false|
      it "deletes the role" do
        expect { subject }.to change(described_class.where(name: "admin"), :count).from(1).to(0)
      end

      it { is_expected.to be true }

      it "clears the cache" do
        expect(Rabarber::Cache).to receive(:delete).with(user.id) if role_assigned
        subject
      end

      it_behaves_like "role name is processed", [:admin]
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

  describe ".assignees" do
    subject { described_class.assignees(role) }

    let(:users) { [User.create!, User.create!] }

    context "when the role exists" do
      let(:role) { "admin" }

      before { described_class.create!(name: "admin") }

      context "when the role is not assigned to any user" do
        it { is_expected.to be_empty }

        it_behaves_like "role name is processed", ["admin"]
      end

      context "when the role is assigned to some users" do
        before { users.each { |user| user.assign_roles(:admin) } }

        it { is_expected.to match_array(users) }

        it_behaves_like "role name is processed", ["admin"]
      end
    end

    context "when the role does not exist" do
      let(:role) { "client" }

      it { is_expected.to be_empty }

      it_behaves_like "role name is processed", ["client"]
    end
  end
end
