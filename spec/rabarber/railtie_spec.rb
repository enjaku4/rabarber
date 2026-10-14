# frozen_string_literal: true

RSpec.describe Rabarber::Railtie do
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

    describe "roleables association declaration" do
      before { Rabarber::Configuration.user_model_name = "Client" }

      it "declares the association with the user model configured in the initializer" do
        subject
        expect(Rabarber::Role.reflect_on_association(:roleables).klass).to eq(Client)
      end

      it "re-declares the association on each run without errors or stale classes" do
        expect { 2.times { DummyApplication.config.to_prepare_blocks.each(&:call) } }.not_to raise_error
        expect(Rabarber::Role.reflect_on_association(:roleables).klass).to eq(Client)
      end
    end
  end

  context "include_roleable initializer" do
    it "includes Rabarber::Roleable in the configured user model when it is autoloaded" do
      expect(User.ancestors).to include(Rabarber::Roleable)
    end

    it "does not include Rabarber::Roleable in other autoloaded models" do
      expect(Project.ancestors).not_to include(Rabarber::Roleable)
    end

    it "registers the hook with every Rails autoloader" do
      Rails.autoloaders.each { allow(_1).to receive(:on_load) }

      described_class.initializers.detect { _1.name == "rabarber.include_roleable" }.run(DummyApplication)

      expect(Rails.autoloaders.to_a).to all(have_received(:on_load))
    end
  end

  context "extend_migration_helpers initializer" do
    subject { initializer.run(DummyApplication) }

    let(:initializer) { described_class.initializers.detect { |i| i.name == "rabarber.extend_migration_helpers" } }

    before do
      allow(ActiveSupport).to receive(:on_load).with(:active_record).and_yield
      allow(ActiveRecord::Migration).to receive(:include).with(Rabarber::MigrationHelpers)
    end

    it "includes Rabarber::MigrationHelpers in ActiveRecord::Migration" do
      subject
      expect(ActiveRecord::Migration).to have_received(:include).with(Rabarber::MigrationHelpers)
    end
  end
end
