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
        expect { subject }.to raise_error(Rabarber::ConfigurationError, "Invalid configuration `cache_enabled`, expected a boolean, got \"invalid\"")
      end
    end

    context "with current_user_method configuration is invalid" do
      subject { described_class.configure { |config| config.current_user_method = 123 } }

      it "raises an error" do
        expect { subject }.to raise_error(Rabarber::ConfigurationError, "Invalid configuration `current_user_method`, expected a symbol or a string, got 123")
      end
    end

    context "with user_model_name configuration is invalid" do
      subject { described_class.configure { |config| config.user_model_name = 123 } }

      it "raises an error" do
        expect { subject }.to raise_error(Rabarber::ConfigurationError, "Invalid configuration `user_model_name`, expected an ActiveRecord model name, got 123")
      end
    end

    context "with user_model configuration is invalid" do
      subject { described_class::Configuration.user_model }

      before { described_class.configure { |config| config.user_model_name = "Rabarber" } }

      it "raises an error" do
        expect { subject }.to raise_error(Rabarber::ConfigurationError, "Invalid configuration `user_model_name`, expected an ActiveRecord model name, got \"Rabarber\"")
      end
    end
  end
end
