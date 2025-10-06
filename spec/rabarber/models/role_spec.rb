# frozen_string_literal: true

RSpec.describe Rabarber::Role do
  describe ".names" do
    subject { described_class.names(context:) }

    let(:context) { nil }

    context "when there are no roles" do
      it { is_expected.to eq([]) }
    end

    context "when there are some roles" do
      let(:role_names) { [:admin, :accountant, :manager] }

      before { role_names.each { |role_name| described_class.create!(name: role_name) } }

      it { is_expected.to match_array(role_names) }
    end

    context "when there are some roles but in a different context" do
      let(:role_names) { [:admin, :manager] }

      before { role_names.each { |role_name| described_class.create!(name: role_name, context_type: "Project") } }

      it { is_expected.to eq([]) }
    end

    context "when context is given" do
      let(:role_names) { [:admin, :manager] }
      let(:project) { Project.create! }
      let(:context) { project }

      before do
        role_names.each { |role_name| described_class.create!(name: role_name, context_type: "Project", context_id: project.id) }

        described_class.create!(name: :accountant)
        described_class.create!(name: :manager, context_type: "Project")
      end

      it { is_expected.to match_array(role_names) }
    end
  end

  describe ".all_names" do
    subject { described_class.all_names }

    context "when there are no roles" do
      it { is_expected.to eq({}) }
    end

    context "when there are some roles" do
      let(:project1) { Project.create! }
      let(:project2) { Project.create! }
      let(:user) { User.create! }

      before do
        described_class.add(:admin)
        described_class.add(:accountant)
        described_class.add(:admin, context: Project)
        described_class.add(:manager, context: Project)
        described_class.add(:manager, context: project1)
        described_class.add(:viewer, context: project2)
        described_class.add(:manager, context: project2)
        described_class.add(:editor, context: user)
      end

      it { is_expected.to eq(nil => [:admin, :accountant], Project => [:admin, :manager], project1 => [:manager], project2 => [:viewer, :manager], user => [:editor]) }

      context "when the instance context can't be found" do
        before { project1.destroy! }

        it { is_expected.to eq(nil => [:admin, :accountant], Project => [:admin, :manager], project2 => [:viewer, :manager], user => [:editor]) }
      end

      context "when the class context doesn't exist" do
        before { described_class.take.update!(context_type: "Foo") }

        it "raises an error" do
          expect { subject }.to raise_error(Rabarber::NotFoundError, "Context not found: class Foo may have been renamed or deleted")
        end
      end

      context "when the instance context's class doesn't exist" do
        before { described_class.find_by(context: project1).update!(context_type: "Foo") }

        it "raises an error" do
          expect { subject }.to raise_error(Rabarber::NotFoundError, "Context not found: class Foo may have been renamed or deleted")
        end
      end
    end
  end

  describe ".add" do
    subject { described_class.add(name, context:) }

    let(:name) { :admin }

    context "when the role does not exist" do
      let(:context) { nil }

      it "creates the role" do
        expect { subject }.to change { described_class.where(name: "admin").count }.from(0).to(1)
      end

      it { is_expected.to be true }
    end

    context "when the role exists" do
      let(:context) { Project.create! }

      before { described_class.create!(name: "admin", context_type: "Project", context_id: context.id) }

      it "does nothing" do
        expect { subject }.not_to change(described_class, :count)
      end

      it { is_expected.to be false }
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
    end

    context "when given an invalid name" do
      let(:name) { :"Invalid-Name" }
      let(:context) { Project.create! }

      it "raises with correct message" do
        expect { subject }.to raise_error(Rabarber::InvalidArgumentError, "Expected a symbol or a string containing only lowercase letters, numbers, and underscores, got :\"Invalid-Name\"")
      end
    end

    context "when given an invalid context" do
      let(:context) { 123 }

      it "raises with correct message" do
        expect { subject }.to raise_error(Rabarber::InvalidContextError, "Expected an instance of ActiveRecord model, a Class, or nil, got 123")
      end
    end
  end

  describe ".rename" do
    subject { described_class.rename(old_name, new_name, context:, force:) }

    let(:old_name) { :admin }
    let(:new_name) { :manager }
    let(:context) { Project.create! }
    let(:force) { false }

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
    end

    shared_examples_for "it renames the role" do |role_assigned: false, processed_context: nil|
      it "renames the role" do
        expect { subject }.to change { role.reload.name }.from("admin").to("manager")
      end

      it { is_expected.to be true }

      it "clears the cache" do
        expect(Rabarber::Core::Cache).to receive(:delete).with([user.id, processed_context], [user.id, :all]) if role_assigned
        subject
      end
    end

    shared_examples_for "it raises an error" do
      it "raises an error" do
        expect { subject }.to raise_error(Rabarber::NotFoundError, "Role not found")
      end
    end

    context "when the role does not exist" do
      let(:context) { Project }

      context "when force is false" do
        let(:force) { false }

        context "when the new role name is already taken" do
          before { described_class.create!(name: "manager", context_type: "Project", context_id: nil) }

          it_behaves_like "it raises an error"
        end

        context "when the new role name is not taken" do
          it_behaves_like "it raises an error"
        end
      end

      context "when force is true" do
        let(:force) { true }

        context "when the new role name is already taken" do
          before { described_class.create!(name: "manager", context_type: "Project", context_id: nil) }

          it_behaves_like "it raises an error"
        end

        context "when the new role name is not taken" do
          it_behaves_like "it raises an error"
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

    context "when given an invalid old name" do
      let(:old_name) { :"Invalid-Name" }

      it "raises with correct message" do
        expect { subject }.to raise_error(Rabarber::InvalidArgumentError, "Expected a symbol or a string containing only lowercase letters, numbers, and underscores, got :\"Invalid-Name\"")
      end
    end

    context "when given an invalid new name" do
      let(:new_name) { :"Invalid-Name" }

      before { described_class.create!(name: :admin, context_type: context.class.name, context_id: context.id) }

      it "raises with correct message" do
        expect { subject }.to raise_error(Rabarber::InvalidArgumentError, "Expected a symbol or a string containing only lowercase letters, numbers, and underscores, got :\"Invalid-Name\"")
      end
    end

    context "when given an invalid context" do
      let(:context) { 123 }

      it "raises with correct message" do
        expect { subject }.to raise_error(Rabarber::InvalidContextError, "Expected an instance of ActiveRecord model, a Class, or nil, got 123")
      end
    end
  end

  describe ".remove" do
    subject { described_class.remove(name, context:, force:) }

    let(:name) { :admin }
    let(:context) { Project.create! }
    let(:force) { false }

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
    end

    shared_examples_for "it deletes the role" do |role_assigned: false, processed_context: nil|
      it "deletes the role" do
        expect { subject }.to change(described_class.where(name: "admin"), :count).from(1).to(0)
      end

      it { is_expected.to be true }

      it "clears the cache" do
        expect(Rabarber::Core::Cache).to receive(:delete).with([user.id, processed_context], [user.id, :all]) if role_assigned
        subject
      end
    end

    shared_examples_for "it raises an error" do
      it "raises an error" do
        expect { subject }.to raise_error(Rabarber::NotFoundError, "Role not found")
      end
    end

    context "when the role does not exist" do
      let(:context) { nil }

      context "when force is false" do
        let(:force) { false }

        it_behaves_like "it raises an error"
      end

      context "when force is true" do
        let(:force) { true }

        it_behaves_like "it raises an error"
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

        before { user.assign_roles(:admin, context:) }

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

    context "when given an invalid name" do
      let(:name) { :"Invalid-Name" }

      it "raises with correct message" do
        expect { subject }.to raise_error(Rabarber::InvalidArgumentError, "Expected a symbol or a string containing only lowercase letters, numbers, and underscores, got :\"Invalid-Name\"")
      end
    end

    context "when given an invalid context" do
      let(:context) { 123 }

      it "raises with correct message" do
        expect { subject }.to raise_error(Rabarber::InvalidContextError, "Expected an instance of ActiveRecord model, a Class, or nil, got 123")
      end
    end
  end

  describe ".assignees" do
    subject { described_class.assignees(role, context:) }

    let(:users) { [User.create!, User.create!] }
    let(:context) { Project.create! }

    context "when the role exists" do
      let(:role) { "admin" }

      before { described_class.create!(name: "admin", context_type: "Project", context_id: context.id) }

      context "when the role is not assigned to any user" do
        it { is_expected.to be_empty }
      end

      context "when the role is assigned to some users" do
        before { users.each { |user| user.assign_roles(:admin, context:) } }

        it { is_expected.to match_array(users) }
      end
    end

    context "when the role does not exist" do
      let(:role) { "client" }

      it { is_expected.to be_empty }
    end

    context "when the role with the same name exists in a different context" do
      let(:role) { "admin" }

      before { described_class.create!(name: "admin", context_type: "Project", context_id: nil) }

      it { is_expected.to be_empty }
    end

    context "when given an invalid name" do
      let(:role) { :"Invalid-Name" }

      it "raises with correct message" do
        expect { subject }.to raise_error(Rabarber::InvalidArgumentError, "Expected a symbol or a string containing only lowercase letters, numbers, and underscores, got :\"Invalid-Name\"")
      end
    end

    context "when given an invalid context" do
      let(:role) { :admin }
      let(:context) { 123 }

      it "raises with correct message" do
        expect { subject }.to raise_error(Rabarber::InvalidContextError, "Expected an instance of ActiveRecord model, a Class, or nil, got 123")
      end
    end
  end

  describe "#context" do
    subject { role.context }

    context "when the role has global context" do
      let(:role) { described_class.create!(name: "admin") }

      it { is_expected.to be_nil }
    end

    context "when the role has an instance context" do
      let(:project) { Project.create! }
      let(:role) { described_class.create!(name: "admin", context_type: project.model_name, context_id: project.id) }

      it { is_expected.to eq(project) }
    end

    context "when the role has a class context" do
      let(:role) { described_class.create!(name: "admin", context_type: "Project") }

      it { is_expected.to eq(Project) }
    end

    context "when the instance context can't be found" do
      let(:role) { described_class.create!(name: "admin", context_type: "Project", context_id: 42) }

      it "raises an error" do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the class context doesn't exist" do
      let(:role) { described_class.create!(name: "admin", context_type: "Foo") }

      it "raises an error" do
        expect { subject }.to raise_error(NameError)
      end
    end
  end

  describe "#prune" do
    subject { described_class.prune }

    let(:project) { Project.create! }
    let!(:role) { described_class.create!(name: "manager", context_type: "Project", context_id: project.id) }

    before { described_class.create!(name: "manager", context_type: "Project", context_id: Project.create!.id) }

    context "when context is missing" do
      before { project.destroy! }

      it "deletes the roles with missing context" do
        expect { subject }.to change { described_class.find_by(id: role.id) }.from(role).to(nil)
      end

      it "does not delete the roles with existing context" do
        expect { subject }.to change(described_class, :count).from(2).to(1)
      end
    end

    context "when context is not missing" do
      it "does not delete any roles" do
        expect { subject }.not_to change(described_class, :count)
      end
    end
  end
end
