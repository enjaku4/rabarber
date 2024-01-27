# frozen_string_literal: true

RSpec.describe Rabarber do
  it "has a version number" do
    expect(Rabarber::VERSION).not_to be nil
  end

  describe ".configure" do
    it "can be configured" do
      described_class.configure do |config|
        config.current_user_method = "user"
        config.must_have_roles = true
        config.when_roles_missing = -> (missing_roles, context) { "#{context}: #{missing_roles}" }
        config.when_unauthorized = -> (controller) { controller.head(418) }
      end

      controller = double

      allow(controller).to receive(:head).with(418).and_return("I'm a teapot")

      expect(Rabarber::Configuration.instance.current_user_method).to eq(:user)
      expect(Rabarber::Configuration.instance.must_have_roles).to be true
      expect(Rabarber::Configuration.instance.when_roles_missing.call([:admin], "context")).to eq("context: [:admin]")
      expect(Rabarber::Configuration.instance.when_unauthorized.call(controller)).to eq("I'm a teapot")
    end

    it "uses Input::Types::Symbols to process current_user_method" do
      input_processor = instance_double(Rabarber::Input::Types::Symbols, process: :user)
      allow(Rabarber::Input::Types::Symbols).to receive(:new).with(
        :user, Rabarber::ConfigurationError, "Configuration 'current_user_method' must be a Symbol or a String"
      ).and_return(input_processor)
      expect(input_processor).to receive(:process).with(no_args)
      described_class.configure { |config| config.current_user_method = :user }
    end

    it "uses Input::Types::Booleans to process must_have_roles" do
      input_processor = instance_double(Rabarber::Input::Types::Booleans, process: true)
      allow(Rabarber::Input::Types::Booleans).to receive(:new).with(
        true, Rabarber::ConfigurationError, "Configuration 'must_have_roles' must be a Boolean"
      ).and_return(input_processor)
      expect(input_processor).to receive(:process).with(no_args)
      described_class.configure { |config| config.must_have_roles = true }
    end

    it "uses Input::Types::Procs to process when_actions_missing" do
      callable = -> (missing_actions, context) { puts("#{context}: #{missing_actions}") }
      input_processor = instance_double(Rabarber::Input::Types::Procs, process: callable)
      allow(Rabarber::Input::Types::Procs).to receive(:new).with(
        callable, Rabarber::ConfigurationError, "Configuration 'when_actions_missing' must be a Proc"
      ).and_return(input_processor)
      expect(input_processor).to receive(:process).with(no_args)
      described_class.configure { |config| config.when_actions_missing = callable }
    end

    it "uses Input::Types::Procs to process when_roles_missing" do
      callable = -> (missing_roles, context) { puts("#{context}: #{missing_roles}") }
      input_processor = instance_double(Rabarber::Input::Types::Procs, process: callable)
      allow(Rabarber::Input::Types::Procs).to receive(:new).with(
        callable, Rabarber::ConfigurationError, "Configuration 'when_roles_missing' must be a Proc"
      ).and_return(input_processor)
      expect(input_processor).to receive(:process).with(no_args)
      described_class.configure { |config| config.when_roles_missing = callable }
    end

    it "uses Input::Types::Procs to process when_unauthorized" do
      callable = -> (controller) { controller.head(418) }
      input_processor = instance_double(Rabarber::Input::Types::Procs, process: callable)
      allow(Rabarber::Input::Types::Procs).to receive(:new).with(
        callable, Rabarber::ConfigurationError, "Configuration 'when_unauthorized' must be a Proc"
      ).and_return(input_processor)
      expect(input_processor).to receive(:process).with(no_args)
      described_class.configure { |config| config.when_unauthorized = callable }
    end

    it "has default configurations" do
      expect(Rabarber::Configuration.instance.current_user_method).to eq(:current_user)
      expect(Rabarber::Configuration.instance.must_have_roles).to be false
      expect(Rabarber::Configuration.instance.when_actions_missing).to be_a(Proc)
      expect(Rabarber::Configuration.instance.when_roles_missing).to be_a(Proc)
      expect(Rabarber::Configuration.instance.when_unauthorized).to be_a(Proc)
    end

    it "raises an error when actions are missing by default" do
      expect { Rabarber::Configuration.instance.when_actions_missing.call([:foo], controller: "Controller") }
        .to raise_error(Rabarber::Error, "Missing actions: [:foo], context: Controller")
    end

    it "logs a warning when roles are missing by default" do
      Rabarber::Configuration.instance.when_roles_missing.call(
        [:missing_role], controller: "Controller", action: "index"
      )
      message = "[Rabarber] Missing roles: [:missing_role], context: Controller#index"
      last_log_line = File.foreach("log/test.log").to_a.last.chomp
      expect(last_log_line).to eq(message)
    end

    context "when misconfigured" do
      context "when current_user_method is invalid" do
        subject { described_class.configure { |config| config.current_user_method = User } }

        it "raises an error" do
          expect { subject }.to raise_error(
            Rabarber::ConfigurationError, "Configuration 'current_user_method' must be a Symbol or a String"
          )
        end
      end

      context "when must_have_roles is not a boolean" do
        subject { described_class.configure { |config| config.must_have_roles = nil } }

        it "raises an error" do
          expect { subject }.to raise_error(
            Rabarber::ConfigurationError, "Configuration 'must_have_roles' must be a Boolean"
          )
        end
      end

      context "when when_actions_missing is not a Proc" do
        subject { described_class.configure { |config| config.when_actions_missing = :foo } }

        it "raises an error" do
          expect { subject }.to raise_error(
            Rabarber::ConfigurationError, "Configuration 'when_actions_missing' must be a Proc"
          )
        end
      end

      context "when when_roles_missing is not a Proc" do
        subject { described_class.configure { |config| config.when_roles_missing = :foo } }

        it "raises an error" do
          expect { subject }.to raise_error(
            Rabarber::ConfigurationError, "Configuration 'when_roles_missing' must be a Proc"
          )
        end
      end

      context "when when_unauthorized is not a Proc" do
        subject { described_class.configure { |config| config.when_unauthorized = :foo } }

        it "raises an error" do
          expect { subject }.to raise_error(
            Rabarber::ConfigurationError, "Configuration 'when_unauthorized' must be a Proc"
          )
        end
      end
    end
  end
end
