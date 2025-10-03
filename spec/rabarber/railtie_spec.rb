# frozen_string_literal: true

RSpec.describe Rabarber::Railtie do
  context "to_prepare" do
    subject { DummyApplication.config.to_prepare_blocks.each(&:call) }

    describe "context class checking" do
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

    describe "permissions reset" do
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

  context "extend_migration_helpers" do
    subject { initializer.run(DummyApplication) }

    let(:initializer) { described_class.initializers.detect { |i| i.name == "rabarber.extend_migration_helpers" } }

    before do
      allow(ActiveSupport).to receive(:on_load).with(:active_record).and_yield
      allow(ActiveRecord::Migration).to receive(:include).with(Rabarber::MigrationHelpers)
    end

    it "includes Rabarber::MigrationHelpers in ActiveRecord::Migration" do
      subject
      expect(ActiveRecord::Migration).to have_received(:include)
    end
  end
end
