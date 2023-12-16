# frozen_string_literal: true

RSpec.describe Rabarber::HasRoles do
  describe "can be included only once" do
    it "raises an error when included twice" do
      expect { Client.include(described_class) }
        .to raise_error(Rabarber::Error, "#{described_class} can only be included once")
    end
  end

  describe "#role?" do
    let(:user) { User.create! }

    before { user.assign_roles(:admin, :manager) }

    context "when wrong argument types are given" do
      [nil, 1, ["admin"], Symbol].each do |wrong_argument|
        it "raises an error when '#{wrong_argument}' is given as a role name" do
          expect { user.role?(wrong_argument) }
            .to raise_error(ArgumentError, "Role names must be symbols or strings")
        end
      end
    end

    it "returns true if the user has the given role" do
      expect(user.role?(:admin)).to be true
    end

    it "returns false if the user does not have the given role" do
      expect(user.role?(:accountant)).to be false
    end
  end

  describe "#has_role?" do
    let(:role_method) { User.new.method(:role?) }
    let(:has_role_method) { User.new.method(:has_role?) }

    it "is an alias for #role?" do
      expect(role_method.original_name).to eq(has_role_method.original_name)
      expect(role_method.source_location).to eq(has_role_method.source_location)
    end
  end

  describe "#assign_roles" do
    subject { user.assign_roles(*roles, create_new: create_new) }

    let(:user) { User.create! }

    context "when wrong argument types are given" do
      [nil, 1, ["admin"], Symbol].each do |wrong_argument|
        it "raises an error when '#{wrong_argument}' is given as a role name" do
          expect { user.assign_roles(wrong_argument) }
            .to raise_error(ArgumentError, "Role names must be symbols or strings")
        end
      end
    end

    context "when create_new is true" do
      let(:create_new) { true }
      let(:roles) { [:admin, :manager] }

      context "when the given roles exist" do
        before do
          roles.each do |role_name|
            Rabarber::Role.create!(name: role_name)
          end
        end

        it "assigns the given roles to the user" do
          subject
          expect(user.roles.names).to match_array(roles)
        end

        it "does not create new roles" do
          expect { subject }.not_to change(Rabarber::Role, :count).from(roles.size)
        end
      end

      context "when the given roles do not exist" do
        it "assigns the given roles to the user" do
          subject
          expect(user.roles.names).to match_array(roles)
        end

        it "creates new roles" do
          expect { subject }.to change(Rabarber::Role, :names).from([]).to(roles)
        end
      end

      context "when some of the given roles exist" do
        before { Rabarber::Role.create!(name: roles.first) }

        it "assigns the given roles to the user" do
          subject
          expect(user.roles.names).to match_array(roles)
        end

        it "creates new roles" do
          expect { subject }.to change(Rabarber::Role, :names).from([roles.first]).to(roles)
        end
      end
    end

    context "when create_new is false" do
      let(:create_new) { false }
      let(:roles) { [:admin, :manager] }

      context "when the given roles exist" do
        before do
          roles.each do |role_name|
            Rabarber::Role.create!(name: role_name)
          end
        end

        it "assigns the given roles to the user" do
          subject
          expect(user.roles.names).to match_array(roles)
        end

        it "does not create new roles" do
          expect { subject }.not_to change(Rabarber::Role, :count).from(roles.size)
        end
      end

      context "when the given roles do not exist" do
        it "does not assign any roles to the user" do
          subject
          expect(user.roles).to be_empty
        end

        it "does not create new roles" do
          expect { subject }.not_to change(Rabarber::Role, :count).from(0)
        end
      end

      context "when some of the given roles exist" do
        before { Rabarber::Role.create!(name: roles.first) }

        it "does not assign any roles to the user" do
          subject
          expect(user.roles.names).to eq([roles.first])
        end

        it "does not create new roles" do
          expect { subject }.not_to change(Rabarber::Role, :count).from(1)
        end
      end
    end
  end

  describe "#revoke_roles" do
    subject { user.revoke_roles(*roles) }

    let(:user) { User.create! }
    let(:roles) { [:admin, :manager] }

    context "when wrong argument types are given" do
      [nil, 1, ["admin"], Symbol].each do |wrong_argument|
        it "raises an error when '#{wrong_argument}' is given as a role name" do
          expect { user.revoke_roles(wrong_argument) }
            .to raise_error(ArgumentError, "Role names must be symbols or strings")
        end
      end
    end

    context "when the user has the given roles" do
      before { user.assign_roles(*roles) }

      it "revokes the given roles from the user" do
        subject
        expect(user.roles).to be_empty
      end
    end

    context "when the user does not have the given roles" do
      before { user.assign_roles(:accountant) }

      it "does not revoke any roles from the user" do
        subject
        expect(user.roles.names).to eq([:accountant])
      end
    end

    context "when the user has some of the given roles" do
      before { user.assign_roles(*roles.first(1)) }

      it "revokes the given roles from the user" do
        subject
        expect(user.roles).to be_empty
      end
    end
  end
end
