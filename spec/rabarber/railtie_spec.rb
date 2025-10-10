# frozen_string_literal: true

RSpec.describe Rabarber::Railtie do
  describe ".server_running?" do
    context "when Rails::Server is defined" do
      before do
        stub_const("Rails::Server", Class.new)
      end

      it "returns true" do
        expect(described_class.server_running?).to be true
      end
    end

    context "when Rails::Server is not defined" do
      it "returns false" do
        expect(described_class.server_running?).to be false
      end
    end
  end

  describe ".table_exists?" do
    let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter) }

    before do
      allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
    end

    context "when rabarber_roles table exists" do
      before do
        allow(connection).to receive(:data_source_exists?).with("rabarber_roles").and_return(true)
      end

      it "returns true" do
        expect(described_class.table_exists?).to be true
      end
    end

    context "when rabarber_roles table does not exist" do
      before do
        allow(connection).to receive(:data_source_exists?).with("rabarber_roles").and_return(false)
      end

      it "returns false" do
        expect(described_class.table_exists?).to be false
      end
    end

    context "when database does not exist" do
      before do
        allow(connection).to receive(:data_source_exists?).with("rabarber_roles").and_raise(ActiveRecord::NoDatabaseError)
      end

      it "returns false" do
        expect(described_class.table_exists?).to be false
      end
    end

    context "when connection is not established" do
      before do
        allow(connection).to receive(:data_source_exists?).with("rabarber_roles").and_raise(ActiveRecord::ConnectionNotEstablished)
      end

      it "returns false" do
        expect(described_class.table_exists?).to be false
      end
    end
  end

  context "to_prepare initializer" do
    subject { DummyApplication.config.to_prepare_blocks.each(&:call) }

    before do
      allow(described_class).to receive_messages(server_running?: server_running, table_exists?: table_exists)
    end

    describe "context class checking" do
      context "when server is running and table exists" do
        let(:server_running) { true }
        let(:table_exists) { true }

        before { Rabarber::Role.create!(context_type:, name: "foo") }

        context "when context exists" do
          let(:context_type) { "Project" }

          it "does not raise an error" do
            expect { subject }.not_to raise_error
          end
        end

        context "when context does not exist" do
          let(:context_type) { "NonExistentClass" }

          it "raises a Rabarber::Error" do
            expect { subject }.to raise_error(
              Rabarber::Error, "Context not found: class `NonExistentClass` may have been renamed or deleted"
            )
          end
        end
      end

      context "when server is not running" do
        let(:server_running) { false }
        let(:table_exists) { true }

        before do
          Rabarber::Role.create!(context_type: "NonExistentClass", name: "foo")
        end

        it "skips context class checking and does not raise an error" do
          expect { subject }.not_to raise_error
        end
      end

      context "when table does not exist" do
        let(:server_running) { true }
        let(:table_exists) { false }

        it "skips context class checking and does not raise an error" do
          expect { subject }.not_to raise_error
        end
      end
    end

    describe "permissions reset" do
      let(:server_running) { true }
      let(:table_exists) { true }

      context "when eager_load is true" do
        it "does not reset permissions" do
          expect(Rabarber::Core::Permissions).not_to receive(:reset!)
          subject
        end
      end

      context "when eager_load is false" do
        before { allow(Rails.configuration).to receive(:eager_load).and_return(false) }

        it "resets permissions" do
          expect(Rabarber::Core::Permissions).to receive(:reset!)
          subject
        end
      end
    end

    describe "roleable module inclusion" do
      let(:server_running) { true }
      let(:table_exists) { true }
      let(:user_model) { class_double(User) }

      before { allow(Rabarber::Configuration).to receive(:user_model).and_return(user_model) }

      context "when user model already includes Rabarber::Roleable" do
        before { allow(user_model).to receive(:<).with(Rabarber::Roleable).and_return(true) }

        it "does not include Rabarber::Roleable again" do
          expect(user_model).not_to receive(:include).with(Rabarber::Roleable)
          subject
        end
      end

      context "when user model does not include Rabarber::Roleable" do
        before { allow(user_model).to receive(:<).with(Rabarber::Roleable).and_return(false) }

        it "includes Rabarber::Roleable in the user model" do
          expect(user_model).to receive(:include).with(Rabarber::Roleable)
          subject
        end
      end
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
