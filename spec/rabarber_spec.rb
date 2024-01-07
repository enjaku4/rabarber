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

    it "has default configurations" do
      expect(Rabarber::Configuration.instance.current_user_method).to eq(:current_user)
      expect(Rabarber::Configuration.instance.must_have_roles).to be false
      expect(Rabarber::Configuration.instance.when_unauthorized).to be_a(Proc)
    end

    context "when misconfigured" do
      context "when current_user_method is not a symbol or a string" do
        [nil, 1, [], {}, User, "", :""].each do |value|
          it "raises an ArgumentError when '#{value}' is given" do
            expect { described_class.configure { |config| config.current_user_method = value } }
              .to raise_error(
                Rabarber::ConfigurationError, "Configuration 'current_user_method' must be a Symbol or a String"
              )
          end
        end
      end

      context "when must_have_roles is not a boolean" do
        [nil, 1, "foo", :foo, [], {}, User].each do |value|
          it "raises an ArgumentError when '#{value}' is given" do
            expect { described_class.configure { |config| config.must_have_roles = value } }
              .to raise_error(Rabarber::ConfigurationError, "Configuration 'must_have_roles' must be a Boolean")
          end
        end
      end

      context "when when_unauthorized is not a Proc" do
        [nil, 1, "foo", :foo, [], {}, User].each do |value|
          it "raises an ArgumentError when '#{value}' is given" do
            expect { described_class.configure { |config| config.when_unauthorized = value } }
              .to raise_error(Rabarber::ConfigurationError, "Configuration 'when_unauthorized' must be a Proc")
          end
        end
      end
    end
  end
end
