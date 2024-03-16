# frozen_string_literal: true

RSpec.describe Rabarber::Logger do
  describe "loggers" do
    describe "rails_logger" do
      subject { described_class.instance.rails_logger }

      it { is_expected.to be Rails.logger }
    end

    describe "audit_logger" do
      subject { described_class.instance.audit_logger }

      it { is_expected.to be_an_instance_of(Logger) }

      it "logs to the correct file" do
        expect(subject.instance_variable_get(:@logdev).dev.path).to eq(Rails.root.join("log/rabarber_audit.log").to_s)
      end
    end
  end

  describe ".log" do
    it "logs the message using Rails.logger" do
      expect(described_class.instance.rails_logger).to receive(:tagged).with("Rabarber") do |&block|
        expect(described_class.instance.rails_logger).to receive(:log).with("foo")
        block.call
      end
      described_class.log(:log, "foo")
    end
  end

  describe ".audit" do
    subject { described_class.audit(:info, "bar") }

    let(:audit_logger) { described_class.instance.audit_logger }

    context "when audit trail is enabled" do
      before do
        allow(Rabarber::Configuration.instance).to receive(:audit_trail_enabled).and_return(true)
      end

      it "logs the message using the audit logger" do
        expect(audit_logger).to receive(:info).with("bar").and_call_original
        subject
      end
    end

    context "when audit trail is disabled" do
      before do
        allow(Rabarber::Configuration.instance).to receive(:audit_trail_enabled).and_return(false)
      end

      it "does not log the message" do
        expect_any_instance_of(Logger).not_to receive(:info)
        subject
      end
    end
  end

  describe "#roleable_identity" do
    subject { described_class.roleable_identity(user, with_roles: with_roles) }

    context "when roleable is present" do
      let(:user) { User.create! }

      before { user.assign_roles(:foo, :bar) }

      context "when with_roles is true" do
        let(:with_roles) { true }

        it "returns the formatted roleable identity with roles" do
          expect(subject).to match(/^User with id: '#{user.id}', roles: (\[:foo, :bar\]|\[:bar, :foo\])$/)
        end
      end

      context "when with_roles is false" do
        let(:with_roles) { false }

        it "returns the formatted roleable identity without roles" do
          expect(subject).to eq("User with id: '#{user.id}'")
        end
      end
    end

    context "when roleable is nil" do
      let(:user) { nil }
      let(:with_roles) { false }

      it "returns 'Unauthenticated user'" do
        expect(subject).to eq("Unauthenticated user")
      end
    end
  end
end
