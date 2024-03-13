# frozen_string_literal: true

RSpec.describe Rabarber do
  it "has a version number" do
    expect(Rabarber::VERSION).not_to be_nil
  end

  describe ".configure" do
    it "can be configured" do
      described_class.configure do |config|
        config.audit_trail_enabled = false
        config.cache_enabled = false
        config.current_user_method = "user"
        config.must_have_roles = true
        config.when_unauthorized = -> (controller) { controller.head(418) }
      end

      controller = double

      allow(controller).to receive(:head).with(418).and_return("I'm a teapot")

      expect(Rabarber::Configuration.instance.audit_trail_enabled).to be false
      expect(Rabarber::Configuration.instance.cache_enabled).to be false
      expect(Rabarber::Configuration.instance.current_user_method).to eq(:user)
      expect(Rabarber::Configuration.instance.must_have_roles).to be true
      expect(Rabarber::Configuration.instance.when_unauthorized.call(controller)).to eq("I'm a teapot")
    end

    it "uses Input::Types::Boolean to process audit_trail_enabled" do
      input_processor = instance_double(Rabarber::Input::Types::Boolean, process: false)
      allow(Rabarber::Input::Types::Boolean).to receive(:new).with(
        false, Rabarber::ConfigurationError, "Configuration 'audit_trail_enabled' must be a Boolean"
      ).and_return(input_processor)
      expect(input_processor).to receive(:process).with(no_args)
      described_class.configure { |config| config.audit_trail_enabled = false }
    end

    it "uses Input::Types::Boolean to process cache_enabled" do
      input_processor = instance_double(Rabarber::Input::Types::Boolean, process: false)
      allow(Rabarber::Input::Types::Boolean).to receive(:new).with(
        false, Rabarber::ConfigurationError, "Configuration 'cache_enabled' must be a Boolean"
      ).and_return(input_processor)
      expect(input_processor).to receive(:process).with(no_args)
      described_class.configure { |config| config.cache_enabled = false }
    end

    it "uses Input::Types::Symbol to process current_user_method" do
      input_processor = instance_double(Rabarber::Input::Types::Symbol, process: :user)
      allow(Rabarber::Input::Types::Symbol).to receive(:new).with(
        :user, Rabarber::ConfigurationError, "Configuration 'current_user_method' must be a Symbol or a String"
      ).and_return(input_processor)
      expect(input_processor).to receive(:process).with(no_args)
      described_class.configure { |config| config.current_user_method = :user }
    end

    it "uses Input::Types::Boolean to process must_have_roles" do
      input_processor = instance_double(Rabarber::Input::Types::Boolean, process: true)
      allow(Rabarber::Input::Types::Boolean).to receive(:new).with(
        true, Rabarber::ConfigurationError, "Configuration 'must_have_roles' must be a Boolean"
      ).and_return(input_processor)
      expect(input_processor).to receive(:process).with(no_args)
      described_class.configure { |config| config.must_have_roles = true }
    end

    it "uses Input::Types::Proc to process when_unauthorized" do
      callable = -> (controller) { controller.head(418) }
      input_processor = instance_double(Rabarber::Input::Types::Proc, process: callable)
      allow(Rabarber::Input::Types::Proc).to receive(:new).with(
        callable, Rabarber::ConfigurationError, "Configuration 'when_unauthorized' must be a Proc"
      ).and_return(input_processor)
      expect(input_processor).to receive(:process).with(no_args)
      described_class.configure { |config| config.when_unauthorized = callable }
    end

    it "has default configurations" do
      expect(Rabarber::Configuration.instance.audit_trail_enabled).to be true
      expect(Rabarber::Configuration.instance.cache_enabled).to be true
      expect(Rabarber::Configuration.instance.current_user_method).to eq(:current_user)
      expect(Rabarber::Configuration.instance.must_have_roles).to be false
      expect(Rabarber::Configuration.instance.when_unauthorized).to be_a(Proc)
    end

    context "when misconfigured" do
      context "when audit_trail_enabled is not a boolean" do
        subject { described_class.configure { |config| config.audit_trail_enabled = nil } }

        it "raises an error" do
          expect { subject }.to raise_error(
            Rabarber::ConfigurationError, "Configuration 'audit_trail_enabled' must be a Boolean"
          )
        end
      end

      context "when cache_enabled is not a boolean" do
        subject { described_class.configure { |config| config.cache_enabled = nil } }

        it "raises an error" do
          expect { subject }.to raise_error(
            Rabarber::ConfigurationError, "Configuration 'cache_enabled' must be a Boolean"
          )
        end
      end

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
