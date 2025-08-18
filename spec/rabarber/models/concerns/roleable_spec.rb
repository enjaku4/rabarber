# frozen_string_literal: true

RSpec.describe Rabarber::Roleable do
  describe "can be included only once" do
    it "raises an error when included twice" do
      expect { Client.include(described_class) }
        .to raise_error(Rabarber::Error, "#{described_class} can only be included once")
    end
  end

  shared_examples_for "role names are validated" do
    let(:roles) { [:Admin, "junior developer"] }

    it "raises an error when the given roles are invalid" do
      expect { subject }.to raise_error(
        Rabarber::InvalidArgumentError,
        "Expected an array of symbols or strings containing only lowercase letters, numbers, and underscores, got [:Admin, \"junior developer\"]"
      )
    end
  end

  describe "#roles" do
    subject { user.roles(context:) }

    let(:user) { User.create! }

    shared_examples_for "it caches user roles" do |processed_context, role_names|
      it "caches user roles" do
        expect(Rabarber::Core::Cache).to receive(:fetch).with([user.id, processed_context]) do |&block|
          result = block.call
          expect(result).to match_array(role_names)
          result
        end
        subject
      end
    end

    context "when the user has no roles" do
      let(:roles) { [] }
      let(:context) { nil }

      it { is_expected.to eq(roles) }

      it_behaves_like "it caches user roles", { context_type: nil, context_id: nil }, []
    end

    context "when the user has some roles" do
      let(:roles) { [:admin, :manager] }
      let(:context) { nil }

      before { user.assign_roles(*roles) }

      it { is_expected.to match_array(roles) }

      it_behaves_like "it caches user roles", { context_type: nil, context_id: nil }, [:admin, :manager]
    end

    context "when the user has the role with the same name in different context" do
      let(:roles) { [:admin] }
      let(:context) { Project }

      before { user.assign_roles(*roles, context: Project.create!) }

      it { is_expected.to be_empty }

      it_behaves_like "it caches user roles", { context_type: "Project", context_id: nil }, []
    end

    context "when the user has the role in the specified context" do
      let(:roles) { [:admin, :developer] }
      let(:context) { Project }

      before { user.assign_roles(*roles, context:) }

      it { is_expected.to match_array(roles) }

      it_behaves_like "it caches user roles", { context_type: "Project", context_id: nil }, [:admin, :developer]
    end

    context "when given an invalid context" do
      let(:context) { 123 }

      it "raises with correct message" do
        expect { subject }.to raise_error(Rabarber::InvalidContextError, "Expected an instance of ActiveRecord model, a Class, or nil, got 123")
      end
    end
  end

  describe "#all_roles" do
    subject { user.all_roles }

    let(:user) { User.create! }

    shared_examples_for "it caches all user roles" do
      it "caches user roles" do
        expect(Rabarber::Core::Cache).to receive(:fetch).with([user.id, :all]) do |&block|
          result = block.call
          expect(result).to eq(all_roles)
          result
        end
        subject
      end
    end

    context "when the user has no roles" do
      it { is_expected.to eq({}) }

      it_behaves_like "it caches all user roles" do
        let(:all_roles) { {} }
      end
    end

    context "when the user has some roles" do
      let(:project) { Project.create! }

      before do
        user.assign_roles(:admin, :manager)
        user.assign_roles(:viewer, context: User)
        user.assign_roles(:manager, context: project)
      end

      it { is_expected.to eq(nil => [:admin, :manager], User => [:viewer], project => [:manager]) }

      it_behaves_like "it caches all user roles" do
        let(:all_roles) { { nil => [:admin, :manager], User => [:viewer], project => [:manager] } }
      end

      context "when the instance context can't be found" do
        before { project.destroy! }

        it { is_expected.to eq(nil => [:admin, :manager], User => [:viewer]) }

        it_behaves_like "it caches all user roles" do
          let(:all_roles) { { nil => [:admin, :manager], User => [:viewer] } }
        end
      end

      context "when the class context doesn't exist" do
        before { Rabarber::Role.find_by(context_type: "User").update!(context_type: "Foo") }

        it "raises an error" do
          expect { subject }.to raise_error(Rabarber::Error, "Context not found: class Foo may have been renamed or deleted")
        end
      end

      context "when the instance context's class doesn't exist" do
        before { Rabarber::Role.find_by(context: project).update!(context_type: "Foo") }

        it "raises an error" do
          expect { subject }.to raise_error(Rabarber::Error, "Context not found: class Foo may have been renamed or deleted")
        end
      end
    end
  end

  describe "#has_role?" do
    subject { user.has_role?(*roles, context:) }

    let(:user) { User.create! }
    let(:context) { nil }

    before { user.assign_roles(:admin, :manager) }

    it_behaves_like "role names are validated"

    context "when the user has at least one of the given roles" do
      let(:roles) { [:admin, :accountant] }

      it { is_expected.to be true }
    end

    context "when the user does not have the given roles" do
      let(:roles) { [:accountant] }

      it { is_expected.to be false }
    end

    context "when the user has the role with the same name in different context" do
      let(:roles) { [:admin] }
      let(:context) { Project }

      before { user.assign_roles(:admin, context: Project.create!) }

      it { is_expected.to be false }
    end

    context "when the user has the role in the specified context" do
      let(:roles) { [:admin] }
      let(:context) { Project }

      before { user.assign_roles(:admin, context:) }

      it { is_expected.to be true }
    end

    context "when given an invalid context" do
      let(:context) { 123 }
      let(:roles) { [:admin] }

      it "raises with correct message" do
        expect { subject }.to raise_error(Rabarber::InvalidContextError, "Expected an instance of ActiveRecord model, a Class, or nil, got 123")
      end
    end
  end

  shared_examples_for "it deletes the cache" do |processed_context|
    it "deletes the cache" do
      expect(Rabarber::Core::Cache).to receive(:delete).with([user.id, processed_context], [user.id, :all]).and_call_original
      subject
    end
  end

  describe "#assign_roles" do
    subject { user.assign_roles(*roles, context:, create_new:) }

    let(:user) { User.create! }

    context "when create_new is true" do
      let(:create_new) { true }
      let(:roles) { [:admin, :manager] }
      let(:context) { Project }

      it_behaves_like "role names are validated"

      context "when the given roles exist" do
        before do
          roles.each do |role_name|
            Rabarber::Role.create!(name: role_name, context_id: nil, context_type: "Project")
          end
        end

        it "assigns the given roles to the user" do
          subject
          expect(user.roles(context:)).to match_array(roles)
        end

        it "does not create new roles" do
          expect { subject }.not_to change(Rabarber::Role, :count).from(roles.size)
        end

        it_behaves_like "it deletes the cache", { context_type: "Project", context_id: nil }

        it { is_expected.to match_array(roles) }
      end

      context "when the given roles do not exist" do
        let(:context) { nil }

        it "assigns the given roles to the user" do
          subject
          expect(user.roles).to match_array(roles)
        end

        it "creates new roles" do
          expect { subject }.to change(Rabarber::Role, :names).from([]).to(roles)
        end

        it_behaves_like "it deletes the cache", { context_type: nil, context_id: nil }

        it { is_expected.to match_array(roles) }
      end

      context "when some of the given roles exist" do
        let(:context) { nil }

        before { Rabarber::Role.create!(name: roles.first) }

        it "assigns the given roles to the user" do
          subject
          expect(user.roles).to match_array(roles)
        end

        it "creates new roles" do
          expect { subject }.to change(Rabarber::Role, :names).from([roles.first]).to(roles)
        end

        it_behaves_like "it deletes the cache", { context_type: nil, context_id: nil }

        it { is_expected.to match_array(roles) }
      end

      context "when the user has the given roles" do
        let(:context) { Project.create! }

        before { user.assign_roles(*roles, context:) }

        it "does not assign any roles to the user" do
          subject
          expect(user.roles(context:)).to match_array(roles)
        end

        it "does not create new roles" do
          expect { subject }.not_to change(Rabarber::Role, :count).from(roles.size)
        end

        it "does not clear the cache" do
          expect(Rabarber::Core::Cache).not_to receive(:delete)
          subject
        end

        it { is_expected.to match_array(roles) }
      end
    end

    context "when create_new is false" do
      let(:create_new) { false }
      let(:roles) { [:admin, :manager] }
      let(:context) { nil }

      it_behaves_like "role names are validated"

      context "when the given roles exist" do
        let(:context) { Project }

        before do
          roles.each do |role_name|
            Rabarber::Role.create!(name: role_name, context_id: nil, context_type: "Project")
          end
        end

        it "assigns the given roles to the user" do
          subject
          expect(user.roles(context:)).to match_array(roles)
        end

        it "does not create new roles" do
          expect { subject }.not_to change(Rabarber::Role, :count).from(roles.size)
        end

        it_behaves_like "it deletes the cache", { context_type: "Project", context_id: nil }

        it { is_expected.to match_array(roles) }
      end

      context "when the given roles do not exist" do
        let(:context) { Project.create! }

        it "does not assign any roles to the user" do
          subject
          expect(user.roles(context:)).to be_empty
        end

        it "does not create new roles" do
          expect { subject }.not_to change(Rabarber::Role, :count).from(0)
        end

        it "does not clear the cache" do
          expect(Rabarber::Core::Cache).not_to receive(:delete)
          subject
        end

        it { is_expected.to be_empty }
      end

      context "when some of the given roles exist" do
        let(:context) { nil }

        before { Rabarber::Role.create!(name: roles.first) }

        it "assignes existing roles" do
          subject
          expect(user.roles).to eq([roles.first])
        end

        it "does not create new roles" do
          expect { subject }.not_to change(Rabarber::Role, :count).from(1)
        end

        it_behaves_like "it deletes the cache", { context_type: nil, context_id: nil }

        it { is_expected.to contain_exactly(roles.first) }
      end

      context "when the user has the given roles" do
        let(:context) { Project }

        before { user.assign_roles(*roles, context:) }

        it "does not assign any roles to the user" do
          subject
          expect(user.roles(context:)).to match_array(roles)
        end

        it "does not create new roles" do
          expect { subject }.not_to change(Rabarber::Role, :count).from(roles.size)
        end

        it "does not clear the cache" do
          expect(Rabarber::Core::Cache).not_to receive(:delete)
          subject
        end

        it { is_expected.to match_array(roles) }
      end
    end

    context "when given an invalid context" do
      let(:user) { User.create! }
      let(:roles) { [:admin] }
      let(:context) { 123 }
      let(:create_new) { true }

      it "raises with correct message" do
        expect { subject }.to raise_error(Rabarber::InvalidContextError, "Expected an instance of ActiveRecord model, a Class, or nil, got 123")
      end
    end
  end

  describe "#revoke_roles" do
    subject { user.revoke_roles(*roles, context:) }

    let(:user) { User.create! }
    let(:roles) { [:admin, :manager] }
    let(:context) { nil }

    it_behaves_like "role names are validated"

    context "when the user has the given roles" do
      let(:context) { Project }

      before { user.assign_roles(*roles, context:) }

      it "revokes the given roles from the user" do
        subject
        expect(user.roles(context:)).to be_empty
      end

      it_behaves_like "it deletes the cache", { context_type: "Project", context_id: nil }

      it { is_expected.to be_empty }
    end

    context "when the user does not have the given roles" do
      let(:context) { Project.create! }

      before { user.assign_roles(:accountant, context:) }

      it "does not revoke any roles from the user" do
        subject
        expect(user.roles(context:)).to eq([:accountant])
      end

      it "does not clear the cache" do
        expect(Rabarber::Core::Cache).not_to receive(:delete)
        subject
      end

      it { is_expected.to contain_exactly(:accountant) }
    end

    context "when the user has some of the given roles" do
      let(:context) { nil }

      before { user.assign_roles(*roles.first(1)) }

      it "revokes these roles from the user" do
        subject
        expect(user.roles).to be_empty
      end

      it_behaves_like "it deletes the cache", { context_type: nil, context_id: nil }

      it { is_expected.to be_empty }
    end

    context "when given an invalid context" do
      let(:context) { 123 }

      it "raises with correct message" do
        expect { subject }.to raise_error(Rabarber::InvalidContextError, "Expected an instance of ActiveRecord model, a Class, or nil, got 123")
      end
    end
  end

  describe "#revoke_all_roles" do
    subject { user.revoke_all_roles }

    let(:user) { User.create! }

    context "when the user has no roles" do
      it "does not change the user's roles" do
        expect { subject }.not_to change(user, :roles)
      end

      it "does not clear the cache" do
        expect(Rabarber::Core::Cache).not_to receive(:delete)
        subject
      end
    end

    context "when the user has some roles" do
      let(:project) { Project.create! }

      before do
        user.assign_roles(:admin, :manager)
        user.assign_roles(:viewer, context: Project)
        user.assign_roles(:manager, context: project)
      end

      it "revokes all roles from the user" do
        expect { subject }.to change(user, :all_roles).from(
          { nil => [:admin, :manager], Project => [:viewer], project => [:manager] }
        ).to({})
      end

      it "does not delete the roles themselves" do
        expect { subject }.not_to change(Rabarber::Role, :count).from(4)
      end

      it "clears the cache" do
        expect(Rabarber::Core::Cache).to receive(:delete).with(
          [user.id, { context_type: nil, context_id: nil }],
          [user.id, { context_type: "Project", context_id: nil }],
          [user.id, { context_type: "Project", context_id: project.id }],
          [user.id, :all]
        )
        subject
      end
    end

    context "when the user has roles with an invalid context key" do
      before do
        user.assign_roles(:admin)
        allow(user).to receive(:all_roles).and_return({ 123 => [:admin] })
      end

      it "raises with correct message" do
        expect { subject }.to raise_error(Rabarber::InvalidContextError, "Expected an instance of ActiveRecord model, a Class, or nil, got 123")
      end
    end
  end
end
