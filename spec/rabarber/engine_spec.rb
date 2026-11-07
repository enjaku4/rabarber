# frozen_string_literal: true

RSpec.describe Rabarber::Engine do
  describe "user model" do
    it "includes Rabarber::Roleable in the configured user model when it is autoloaded" do
      expect(User.ancestors).to include(Rabarber::Roleable)
    end

    it "does not include Rabarber::Roleable in other autoloaded models" do
      expect(Project.ancestors).not_to include(Rabarber::Roleable)
    end
  end

  describe "code reloading" do
    subject { Rails.application.reloader.prepare! }

    let!(:controller_rules_were) { Rabarber::Core::Permissions.controller_rules.dup }
    let!(:action_rules_were) { Rabarber::Core::Permissions.action_rules.dup }
    let!(:controller) do
      Class.new(ActionController::Base) do
        include Rabarber::Authorization

        grant_access roles: :admin
        grant_access action: :index, roles: :admin
      end
    end

    after do
      Rabarber::Core::Permissions.controller_rules.replace(controller_rules_were)
      Rabarber::Core::Permissions.action_rules.replace(action_rules_were)
    end

    context "when eager loading is off" do
      before { allow(Rails.configuration).to receive(:eager_load).and_return(false) }

      it "forgets the access rules so that reloaded controllers declare them again" do
        subject
        expect(Rabarber::Core::Permissions.controller_rules).not_to have_key(controller)
        expect(Rabarber::Core::Permissions.action_rules).not_to have_key(controller)
      end
    end

    context "when eager loading is on" do
      it "keeps the access rules" do
        subject
        expect(Rabarber::Core::Permissions.controller_rules).to have_key(controller)
        expect(Rabarber::Core::Permissions.action_rules).to have_key(controller)
      end
    end
  end

  describe "migrations" do
    it "can use the migration helpers" do
      expect(ActiveRecord::Migration.new).to respond_to(:migrate_authorization_context!, :delete_authorization_context!)
    end
  end
end
