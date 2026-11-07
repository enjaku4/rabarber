# frozen_string_literal: true

RSpec.describe Rabarber::MigrationHelpers do
  let(:dummy_migration) { Class.new { include Rabarber::MigrationHelpers }.new }

  before do
    User.create!.assign_roles(:manager, context: User)
    User.create!.assign_roles(:admin, context: User.create!)
    User.create!.assign_roles(:admin, context: Project)
  end

  describe "#migrate_authorization_context!" do
    it "migrates roles from old context class to new context class" do
      roles = Rabarber::Role.where(context_type: "User")

      expect(roles.count).to eq(2)

      dummy_migration.migrate_authorization_context!("User", "Client")

      expect(Rabarber::Role.where(id: roles.pluck(:id)).pluck(:context_type)).to all(eq("Client"))
    end

    it "does nothing when no roles exist in the old context" do
      expect { dummy_migration.migrate_authorization_context!("Ticket", "Task") }.not_to(change { Rabarber::Role.pluck(:context_type) })
    end

    context "errors" do
      [nil, " ", 1, [1, 2], {}, User].each do |invalid_context|
        it "raises if old context class is invalid: #{invalid_context.inspect}" do
          expect { dummy_migration.migrate_authorization_context!(invalid_context, "Client") }.to raise_error(
            Rabarber::InvalidArgumentError, "Expected a non-empty string, got `#{invalid_context.inspect}`"
          )
        end

        it "raises if new context class is invalid: #{invalid_context.inspect}" do
          expect { dummy_migration.migrate_authorization_context!("User", invalid_context) }.to raise_error(
            Rabarber::InvalidArgumentError, "Expected a non-empty string, got `#{invalid_context.inspect}`"
          )
        end
      end
    end
  end

  describe "#delete_authorization_context!" do
    it "deletes roles for the given context" do
      roles = Rabarber::Role.where(context_type: "User")

      expect(roles.count).to eq(2)

      dummy_migration.delete_authorization_context!("User")

      expect(Rabarber::Role.exists?(id: roles.pluck(:id))).to be false
    end

    it "does nothing when no roles exist in the context" do
      expect { dummy_migration.delete_authorization_context!("Ticket") }.not_to change(Rabarber::Role, :count)
    end

    context "errors" do
      [nil, " ", 1, [1, 2], {}, User].each do |invalid_context|
        it "raises if context class is invalid: #{invalid_context.inspect}" do
          expect { dummy_migration.delete_authorization_context!(invalid_context) }.to raise_error(
            Rabarber::InvalidArgumentError, "Expected a non-empty string, got `#{invalid_context.inspect}`"
          )
        end
      end
    end
  end
end
