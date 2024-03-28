# frozen_string_literal: true

RSpec.describe Rabarber::Audit::Logger do
  describe "#logger" do
    subject { described_class.instance.logger }

    it { is_expected.to be_an_instance_of(Logger) }

    it "logs to the correct file" do
      expect(subject.instance_variable_get(:@logdev).dev.path).to eq(Rails.root.join("log/rabarber_audit.log").to_s)
    end
  end

  describe ".log" do
    subject { described_class.log(:info, "bar") }

    let(:logger) { described_class.instance.logger }

    context "when audit trail is enabled" do
      before { allow(Rabarber::Configuration.instance).to receive(:audit_trail_enabled).and_return(true) }

      it "logs the message using the audit logger" do
        expect(logger).to receive(:info).with("bar").and_call_original
        subject
      end
    end

    context "when audit trail is disabled" do
      before { allow(Rabarber::Configuration.instance).to receive(:audit_trail_enabled).and_return(false) }

      it "does not log the message" do
        expect_any_instance_of(Logger).not_to receive(:info)
        subject
      end
    end
  end
end
