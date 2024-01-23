# frozen_string_literal: true

RSpec.describe Rabarber do
  it "has a version number" do
    expect(Rabarber::VERSION).not_to be nil
  end

  describe ".configure" do
    let(:controller) { double }

    before do
      allow(controller).to receive(:head).with(418).and_return("I'm a teapot")
    end

    it "can be configured" do
      described_class.configure do |config|
        config.current_user_method = "user"
        config.must_have_roles = true
        config.when_unauthorized = ->(controller) { controller.head(418) }
      end

      expect(Rabarber::Configuration.instance.current_user_method).to eq(:user)
      expect(Rabarber::Configuration.instance.must_have_roles).to be true
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

    it "uses Input::Types::Callables to process when_unauthorized" do
      callable = ->(controller) { controller.head(418) }
      input_processor = instance_double(Rabarber::Input::Types::Callables, process: callable)
      allow(Rabarber::Input::Types::Callables).to receive(:new).with(
        callable, Rabarber::ConfigurationError, "Configuration 'when_unauthorized' must be a Proc"
      ).and_return(input_processor)
      expect(input_processor).to receive(:process).with(no_args)
      described_class.configure { |config| config.when_unauthorized = callable }
    end

    it "has default configurations" do
      expect(Rabarber::Configuration.instance.current_user_method).to eq(:current_user)
      expect(Rabarber::Configuration.instance.must_have_roles).to be false
      expect(Rabarber::Configuration.instance.when_unauthorized).to be_a(Proc)
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
