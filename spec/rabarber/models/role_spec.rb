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
    subject { described_class.names(context: context) }

    let(:context) { nil }

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

    context "when there are some roles but in a different context" do
      let(:role_names) { [:admin, :manager] }

      before do
        role_names.each do |role_name|
          described_class.create!(name: role_name, context_type: "Project")
        end
      end

      it { is_expected.to eq([]) }
    end

    context "when context is given" do
      let(:role_names) { [:admin, :manager] }
      let(:project) { Project.create! }
      let(:context) { project }

      before do
        role_names.each do |role_name|
          described_class.create!(name: role_name, context_type: "Project", context_id: project.id)
        end

        described_class.create!(name: :accountant)
        described_class.create!(name: :manager, context_type: "Project")
      end

      it "returns an array of role names in the given context" do
        expect(subject).to match_array(role_names)
      end

      it "uses Input::Context to process the given context" do
        input_processor = instance_double(Rabarber::Input::Context)
        allow(Rabarber::Input::Context).to receive(:new).with(project).and_return(input_processor)
        expect(input_processor).to receive(:process)
        subject
      end
    end
  end

  shared_examples_for "role name is processed" do |roles|
    it "uses Input::Role to process the given roles" do
      roles.each do |role|
        input_processor = instance_double(Rabarber::Input::Role, process: role)
        allow(Rabarber::Input::Role).to receive(:new).with(role).and_return(input_processor)
        expect(input_processor).to receive(:process)
      end
      subject
    end
  end

  describe ".add" do
    subject { described_class.add(:admin, context: context) }

    context "when the role does not exist" do
      let(:context) { nil }

      it "creates the role" do
        expect { subject }.to change { described_class.where(name: "admin").count }.from(0).to(1)
      end

      it { is_expected.to be true }

      it_behaves_like "role name is processed", [:admin]
    end

    context "when the role exists" do
      let(:context) { Project.create! }

      before { described_class.create!(name: "admin", context_type: "Project", context_id: context.id) }

      it "does nothing" do
        expect { subject }.not_to change(described_class, :count)
      end

      it { is_expected.to be false }

      it_behaves_like "role name is processed", [:admin]
    end

    context "when the role with the same name exists in a different context" do
      let(:context) { Project }

      before { described_class.create!(name: "admin") }

      it "creates the role" do
        expect { subject }.to change {
          described_class.where(name: "admin", context_type: "Project", context_id: nil).count
        }.from(0).to(1)
      end

      it { is_expected.to be true }

      it_behaves_like "role name is processed", [:admin]
    end
  end

  describe ".rename" do
    subject { described_class.rename(:admin, :manager, context: context, force: force) }

    shared_examples_for "it does nothing" do |role_exists: true|
      if role_exists
        it "does nothing" do
          expect { subject }.not_to change(role, :name)
        end
      end

      it { is_expected.to be false }

      it "does not clear the cache" do
        expect(Rabarber::Core::Cache).not_to receive(:delete)
        subject
      end

      it_behaves_like "role name is processed", [:admin, :manager]
    end

    shared_examples_for "it renames the role" do |role_assigned: false, processed_context: nil|
      it "renames the role" do
        expect { subject }.to change { role.reload.name }.from("admin").to("manager")
      end

      it { is_expected.to be true }

      it "clears the cache" do
        expect(Rabarber::Core::Cache).to receive(:delete).with(user.id, context: processed_context) if role_assigned
        subject
      end

      it_behaves_like "role name is processed", [:admin, :manager]
    end

    context "when the role does not exist" do
      let(:context) { Project }

      context "when force is false" do
        let(:force) { false }

        context "when the new role name is already taken" do
          before { described_class.create!(name: "manager", context_type: "Project", context_id: nil) }

          it_behaves_like "it does nothing", role_exists: false
        end

        context "when the new role name is not taken" do
          it_behaves_like "it does nothing", role_exists: false
        end
      end

      context "when force is true" do
        let(:force) { true }

        context "when the new role name is already taken" do
          before { described_class.create!(name: "manager", context_type: "Project", context_id: nil) }

          it_behaves_like "it does nothing", role_exists: false
        end

        context "when the new role name is not taken" do
          it_behaves_like "it does nothing", role_exists: false
        end
      end
    end

    context "when the role exists" do
      let!(:role) { described_class.create!(name: "admin") } # rubocop:disable RSpec/LetSetup
      let(:context) { nil }

      context "when the role is not assigned to any user" do
        context "when force is false" do
          let(:force) { false }

          context "when the new role name is already taken" do
            before { described_class.create!(name: "manager", context_type: nil, context_id: nil) }

            it_behaves_like "it does nothing"
          end

          context "when the new role name is not taken" do
            it_behaves_like "it renames the role"
          end
        end

        context "when force is true" do
          let(:force) { true }

          context "when the new role name is already taken" do
            before { described_class.create!(name: "manager", context_type: nil, context_id: nil) }

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
            before { described_class.create!(name: "manager", context_type: nil, context_id: nil) }

            it_behaves_like "it does nothing"
          end

          context "when the new role name is not taken" do
            it_behaves_like "it does nothing"
          end
        end

        context "when force is true" do
          let(:force) { true }

          context "when the new role name is already taken" do
            before { described_class.create!(name: "manager", context_type: nil, context_id: nil) }

            it_behaves_like "it does nothing"
          end

          context "when the new role name is not taken" do
            it_behaves_like "it renames the role", role_assigned: true, processed_context: { context_type: nil, context_id: nil }
          end
        end
      end
    end
  end

  describe ".remove" do
    subject { described_class.remove(:admin, context: context, force: force) }

    shared_examples_for "it does nothing" do
      before { described_class.create!(name: "manager") }

      it "does nothing" do
        expect { subject }.not_to change(described_class, :count)
      end

      it { is_expected.to be false }

      it "does not clear the cache" do
        expect(Rabarber::Core::Cache).not_to receive(:delete)
        subject
      end

      it_behaves_like "role name is processed", [:admin]
    end

    shared_examples_for "it deletes the role" do |role_assigned: false, processed_context: nil|
      it "deletes the role" do
        expect { subject }.to change(described_class.where(name: "admin"), :count).from(1).to(0)
      end

      it { is_expected.to be true }

      it "clears the cache" do
        expect(Rabarber::Core::Cache).to receive(:delete).with(user.id, context: processed_context) if role_assigned
        subject
      end

      it_behaves_like "role name is processed", [:admin]
    end

    context "when the role does not exist" do
      let(:context) { nil }

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
      let(:context) { Project }

      before { described_class.create!(name: "admin", context_id: nil, context_type: "Project") }

      context "when the role is not assigned to any user" do
        context "when force is false" do
          let(:force) { false }

          it_behaves_like "it deletes the role", processed_context: { context_type: "Project", context_id: nil }
        end

        context "when force is true" do
          let(:force) { true }

          it_behaves_like "it deletes the role", processed_context: { context_type: "Project", context_id: nil }
        end
      end

      context "when the role is assigned to some users" do
        let(:user) { User.create! }

        before { user.assign_roles(:admin, context: context) }

        context "when force is false" do
          let(:force) { false }

          it_behaves_like "it does nothing"
        end

        context "when force is true" do
          let(:force) { true }

          it_behaves_like "it deletes the role", role_assigned: true, processed_context: { context_type: "Project", context_id: nil }
        end
      end
    end
  end

  describe ".assignees" do
    subject { described_class.assignees(role, context: context) }

    let(:users) { [User.create!, User.create!] }
    let(:context) { Project.create! }

    context "when the role exists" do
      let(:role) { "admin" }

      before { described_class.create!(name: "admin", context_type: "Project", context_id: context.id) }

      context "when the role is not assigned to any user" do
        it { is_expected.to be_empty }

        it_behaves_like "role name is processed", ["admin"]
      end

      context "when the role is assigned to some users" do
        before { users.each { |user| user.assign_roles(:admin, context: context) } }

        it { is_expected.to match_array(users) }

        it_behaves_like "role name is processed", ["admin"]
      end
    end

    context "when the role does not exist" do
      let(:role) { "client" }

      it { is_expected.to be_empty }

      it_behaves_like "role name is processed", ["client"]
    end

    context "when the role with the same name exists in a different context" do
      let(:role) { "admin" }

      before { described_class.create!(name: "admin", context_type: "Project", context_id: nil) }

      it { is_expected.to be_empty }

      it_behaves_like "role name is processed", ["admin"]
    end
  end
end
