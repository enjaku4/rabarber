# frozen_string_literal: true

RSpec.describe Rabarber::Engine do
  context "to_prepare initializer" do
    subject { DummyApplication.config.to_prepare_blocks.each(&:call) }

    after do
      Rabarber::Configuration.reset_to_defaults!
      DummyApplication.config.to_prepare_blocks.each(&:call)
    end

    it "does not query the database" do
      queries = []

      ActiveSupport::Notifications.subscribed(-> (*, payload) { queries << payload[:sql] }, "sql.active_record") { subject }

      expect(queries).to be_empty
    end

    context "when the configured user model does not exist" do
      before { Rabarber::Configuration.user_model_name = "NonExistentModel" }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    describe "permissions reset" do
      before { allow(Rabarber::Core::Permissions).to receive(:reset!) }

      context "when eager_load is true" do
        it "does not reset permissions" do
          subject
          expect(Rabarber::Core::Permissions).not_to have_received(:reset!)
        end
      end

      context "when eager_load is false" do
        before { allow(Rails.configuration).to receive(:eager_load).and_return(false) }

        it "resets permissions" do
          subject
          expect(Rabarber::Core::Permissions).to have_received(:reset!)
        end
      end
    end
  end

  describe "user model" do
    it "includes Rabarber::Roleable in the configured user model when it is autoloaded" do
      expect(User.ancestors).to include(Rabarber::Roleable)
    end

    it "does not include Rabarber::Roleable in other autoloaded models" do
      expect(Project.ancestors).not_to include(Rabarber::Roleable)
    end
  end

  describe "migrations" do
    it "can use the migration helpers" do
      expect(ActiveRecord::Migration.new).to respond_to(:migrate_authorization_context!, :delete_authorization_context!)
    end
  end
end
