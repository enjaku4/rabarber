# frozen_string_literal: true

RSpec.describe Rabarber::HasRoles do
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
        "Role names must be Symbols or Strings and may only contain lowercase letters, numbers and underscores"
      )
    end
  end

  shared_examples_for "role names are processed" do
    let(:roles) { [:admin, :manager] }

    it "uses Input::Roles to process the given roles" do
      input_processor = instance_double(Rabarber::Input::Roles, process: roles)
      allow(Rabarber::Input::Roles).to receive(:new).with(roles).and_return(input_processor)
      expect(input_processor).to receive(:process).with(no_args)
      subject
    end
  end

  describe "#roles" do
    subject { user.roles }

    let(:user) { User.create! }

    shared_examples_for "it caches user roles" do
      it "caches user roles" do
        expect(Rabarber::Cache).to receive(:fetch)
          .with(Rabarber::Cache.key_for(user.id), expires_in: 1.hour, race_condition_ttl: 5.seconds) do |&block|
            result = block.call
            expect(result).to match_array(roles)
            result
          end
        subject
      end
    end

    context "when the user has no roles" do
      let(:roles) { [] }

      it { is_expected.to eq(roles) }

      it_behaves_like "it caches user roles"
    end

    context "when the user has some roles" do
      let(:roles) { [:admin, :manager] }

      before { user.assign_roles(*roles) }

      it { is_expected.to match_array(roles) }

      it_behaves_like "it caches user roles"
    end
  end

  describe "#has_role?" do
    subject { user.has_role?(*roles) }

    let(:user) { User.create! }

    before { user.assign_roles(:admin, :manager) }

    it_behaves_like "role names are validated"
    it_behaves_like "role names are processed"

    context "when the user has at least one of the given roles" do
      let(:roles) { [:admin, :accountant] }

      it { is_expected.to be true }
    end

    context "when the user does not have the given roles" do
      let(:roles) { [:accountant] }

      it { is_expected.to be false }
    end
  end

  shared_examples_for "it deletes the cache" do
    before { allow(Rabarber::Cache).to receive(:delete).with(Rabarber::Cache::ALL_ROLES_KEY).and_call_original }

    it "deletes the cache" do
      expect(Rabarber::Cache).to receive(:delete).with(Rabarber::Cache.key_for(user.id)).and_call_original
      subject
    end
  end

  describe "#assign_roles" do
    subject { user.assign_roles(*roles, create_new: create_new) }

    let(:user) { User.create! }

    context "when create_new is true" do
      let(:create_new) { true }
      let(:roles) { [:admin, :manager] }

      it_behaves_like "role names are validated"
      it_behaves_like "role names are processed"

      context "when the given roles exist" do
        before do
          roles.each do |role_name|
            Rabarber::Role.create!(name: role_name)
          end
        end

        it "assigns the given roles to the user" do
          subject
          expect(user.roles).to match_array(roles)
        end

        it "does not create new roles" do
          expect { subject }.not_to change(Rabarber::Role, :count).from(roles.size)
        end

        it_behaves_like "it deletes the cache"

        it { is_expected.to match_array(roles) }
      end

      context "when the given roles do not exist" do
        it "assigns the given roles to the user" do
          subject
          expect(user.roles).to match_array(roles)
        end

        it "creates new roles" do
          expect { subject }.to change(Rabarber::Role, :names).from([]).to(roles)
        end

        it_behaves_like "it deletes the cache"

        it { is_expected.to match_array(roles) }
      end

      context "when some of the given roles exist" do
        before { Rabarber::Role.create!(name: roles.first) }

        it "assigns the given roles to the user" do
          subject
          expect(user.roles).to match_array(roles)
        end

        it "creates new roles" do
          expect { subject }.to change(Rabarber::Role, :names).from([roles.first]).to(roles)
        end

        it_behaves_like "it deletes the cache"

        it { is_expected.to match_array(roles) }
      end

      context "when the user has the given roles" do
        before { user.assign_roles(*roles) }

        it "does not assign any roles to the user" do
          subject
          expect(user.roles).to match_array(roles)
        end

        it "does not create new roles" do
          expect { subject }.not_to change(Rabarber::Role, :count).from(roles.size)
        end

        it "does not clear the cache" do
          expect(Rabarber::Cache).not_to receive(:delete)
          subject
        end

        it { is_expected.to match_array(roles) }
      end
    end

    context "when create_new is false" do
      let(:create_new) { false }
      let(:roles) { [:admin, :manager] }

      it_behaves_like "role names are validated"
      it_behaves_like "role names are processed"

      context "when the given roles exist" do
        before do
          roles.each do |role_name|
            Rabarber::Role.create!(name: role_name)
          end
        end

        it "assigns the given roles to the user" do
          subject
          expect(user.roles).to match_array(roles)
        end

        it "does not create new roles" do
          expect { subject }.not_to change(Rabarber::Role, :count).from(roles.size)
        end

        it_behaves_like "it deletes the cache"

        it { is_expected.to match_array(roles) }
      end

      context "when the given roles do not exist" do
        it "does not assign any roles to the user" do
          subject
          expect(user.roles).to be_empty
        end

        it "does not create new roles" do
          expect { subject }.not_to change(Rabarber::Role, :count).from(0)
        end

        it "does not clear the cache" do
          expect(Rabarber::Cache).not_to receive(:delete)
          subject
        end

        it { is_expected.to be_empty }
      end

      context "when some of the given roles exist" do
        before { Rabarber::Role.create!(name: roles.first) }

        it "does not assign any roles to the user" do
          subject
          expect(user.roles).to eq([roles.first])
        end

        it "does not create new roles" do
          expect { subject }.not_to change(Rabarber::Role, :count).from(1)
        end

        it_behaves_like "it deletes the cache"

        it { is_expected.to contain_exactly(roles.first) }
      end

      context "when the user has the given roles" do
        before { user.assign_roles(*roles) }

        it "does not assign any roles to the user" do
          subject
          expect(user.roles).to match_array(roles)
        end

        it "does not create new roles" do
          expect { subject }.not_to change(Rabarber::Role, :count).from(roles.size)
        end

        it "does not clear the cache" do
          expect(Rabarber::Cache).not_to receive(:delete)
          subject
        end

        it { is_expected.to match_array(roles) }
      end
    end
  end

  describe "#revoke_roles" do
    subject { user.revoke_roles(*roles) }

    let(:user) { User.create! }
    let(:roles) { [:admin, :manager] }

    it_behaves_like "role names are validated"
    it_behaves_like "role names are processed"

    context "when the user has the given roles" do
      before { user.assign_roles(*roles) }

      it "revokes the given roles from the user" do
        subject
        expect(user.roles).to be_empty
      end

      it_behaves_like "it deletes the cache"

      it { is_expected.to be_empty }
    end

    context "when the user does not have the given roles" do
      before { user.assign_roles(:accountant) }

      it "does not revoke any roles from the user" do
        subject
        expect(user.roles).to eq([:accountant])
      end

      it "does not clear the cache" do
        expect(Rabarber::Cache).not_to receive(:delete)
        subject
      end

      it { is_expected.to contain_exactly(:accountant) }
    end

    context "when the user has some of the given roles" do
      before { user.assign_roles(*roles.first(1)) }

      it "revokes the given roles from the user" do
        subject
        expect(user.roles).to be_empty
      end

      it_behaves_like "it deletes the cache"

      it { is_expected.to be_empty }
    end
  end

  describe "#roleable_class" do
    subject { described_class.roleable_class }

    it { is_expected.to eq(User) }
  end
end
