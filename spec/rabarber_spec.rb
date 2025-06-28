# frozen_string_literal: true

RSpec.describe Rabarber do
  let(:config) { Rabarber::Configuration }

  it "has a version number" do
    expect(Rabarber::VERSION).not_to be_nil
  end

  describe ".configure" do
    context "when not configured" do
      it "has default configurations" do
        expect(config.cache_enabled).to be true
        expect(config.current_user_method).to eq(:current_user)
        expect(config.user_model).to eq(User)
      end
    end

    context "when configured" do
      before do
        described_class.configure do |config|
          config.cache_enabled = false
          config.current_user_method = "user"
          config.user_model_name = "Client"
        end
      end

      it "applies custom configurations" do
        expect(config.cache_enabled).to be false
        expect(config.current_user_method).to eq(:user)
        expect(config.user_model).to eq(Client)
      end
    end
  end

  context "when misconfigured" do
    context "with cache_enabled configuration is invalid" do
      subject { described_class.configure { |config| config.cache_enabled = "invalid" } }

      it "raises an error" do
        expect { subject }.to raise_error(Rabarber::ConfigurationError, "Configuration `cache_enabled` must be a Boolean")
      end

      it "uses Boolean input processor" do
        double = instance_double(Rabarber::Input::Types::Boolean, process: false)
        allow(Rabarber::Input::Types::Boolean).to receive(:new).with(
          "invalid", Rabarber::ConfigurationError, "Configuration `cache_enabled` must be a Boolean"
        ).and_return(double)
        subject
        expect(double).to have_received(:process)
      end
    end

    context "with current_user_method configuration is invalid" do
      subject { described_class.configure { |config| config.current_user_method = 123 } }

      it "raises an error" do
        expect { subject }.to raise_error(Rabarber::ConfigurationError, "Configuration `current_user_method` must be a Symbol or a String")
      end

      it "uses Symbol input processor" do
        double = instance_double(Rabarber::Input::Types::Symbol, process: :user)
        allow(Rabarber::Input::Types::Symbol).to receive(:new).with(
          123, Rabarber::ConfigurationError, "Configuration `current_user_method` must be a Symbol or a String"
        ).and_return(double)
        subject
        expect(double).to have_received(:process)
      end
    end

    context "with user_model_name configuration is invalid" do
      subject { Rabarber::Configuration.user_model }

      before { described_class.configure { |config| config.user_model_name = 123 } }

      it "raises an error" do
        expect { subject }.to raise_error(Rabarber::ConfigurationError, "Configuration `user_model_name` must be an ActiveRecord model name")
      end

      it "uses ArModel input processor" do
        double = instance_double(Rabarber::Input::ArModel, process: Client)
        allow(Rabarber::Input::ArModel).to receive(:new).with(
          123, Rabarber::ConfigurationError, "Configuration `user_model_name` must be an ActiveRecord model name"
        ).and_return(double)
        subject
        expect(double).to have_received(:process)
      end
    end
  end
end
