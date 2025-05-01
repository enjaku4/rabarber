# frozen_string_literal: true

RSpec.describe Rabarber do
  let(:config) { Rabarber::Configuration.instance }

  it "has a version number" do
    expect(Rabarber::VERSION).not_to be_nil
  end

  describe ".configure" do
    context "when not configured" do
      it "has default configurations" do
        expect(config.audit_trail_enabled).to be true
        expect(config.cache_enabled).to be true
        expect(config.current_user_method).to eq(:current_user)
        expect(config.user_model).to eq(User)
      end
    end

    context "when configured" do
      before do
        described_class.configure do |config|
          config.audit_trail_enabled = false
          config.cache_enabled = false
          config.current_user_method = "user"
          config.user_model_name = "Client"
        end
      end

      it "can be configured" do
        expect(config.audit_trail_enabled).to be false
        expect(config.cache_enabled).to be false
        expect(config.current_user_method).to eq(:user)
        expect(config.user_model).to eq(Client)
      end

      it "uses Input::Types::Boolean to process audit_trail_enabled" do
        expect_input_processor(Rabarber::Input::Types::Boolean, false, "Configuration 'audit_trail_enabled' must be a Boolean")
        described_class.configure { |config| config.audit_trail_enabled = false }
      end

      it "uses Input::Types::Boolean to process cache_enabled" do
        expect_input_processor(Rabarber::Input::Types::Boolean, false, "Configuration 'cache_enabled' must be a Boolean")
        described_class.configure { |config| config.cache_enabled = false }
      end

      it "uses Input::Types::Symbol to process current_user_method" do
        expect_input_processor(Rabarber::Input::Types::Symbol, :user, "Configuration 'current_user_method' must be a Symbol or a String")
        described_class.configure { |config| config.current_user_method = :user }
      end

      it "uses Input::Types::ArModel to process user_model_name" do
        described_class.configure { |config| config.user_model_name = "Client" }
        input_processor = instance_double(Rabarber::Input::ArModel, process: "Client")
        allow(Rabarber::Input::ArModel).to receive(:new).with("Client", Rabarber::ConfigurationError, "Configuration 'user_model_name' must be an ActiveRecord model name").and_return(input_processor)
        expect(input_processor).to receive(:process)
        Rabarber::Configuration.instance.user_model
      end
    end

    context "when misconfigured" do
      it "raises an error for invalid audit_trail_enabled" do
        expect_configuration_error(:audit_trail_enabled, nil, "Configuration 'audit_trail_enabled' must be a Boolean")
      end

      it "raises an error for invalid cache_enabled" do
        expect_configuration_error(:cache_enabled, nil, "Configuration 'cache_enabled' must be a Boolean")
      end

      it "raises an error for invalid current_user_method" do
        expect_configuration_error(:current_user_method, User, "Configuration 'current_user_method' must be a Symbol or a String")
      end

      it "raises an error for invalid user_model_name" do
        described_class.configure { |config| config.user_model_name = "Rabarber::Core" }
        expect { Rabarber::Configuration.instance.user_model }
          .to raise_error(Rabarber::ConfigurationError, "Configuration 'user_model_name' must be an ActiveRecord model name")
      end
    end
  end

  def expect_input_processor(type, value, error_message)
    input_processor = instance_double(type, process: value)
    allow(type).to receive(:new).with(value, Rabarber::ConfigurationError, error_message).and_return(input_processor)
    expect(input_processor).to receive(:process)
  end

  def expect_configuration_error(attribute, value, error_message)
    expect { described_class.configure { |config| config.send(:"#{attribute}=", value) } }
      .to raise_error(Rabarber::ConfigurationError, error_message)
  end
end
