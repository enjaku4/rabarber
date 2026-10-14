# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rabarber::Inputs::DynamicRule do
  describe "#process" do
    subject { described_class.new(dynamic_rule, error: Rabarber::InvalidArgumentError, message: "Error").process }

    context "when the given dynamic rule is valid" do
      context "when a string is given" do
        let(:dynamic_rule) { "foo?" }

        it { is_expected.to eq(:foo?) }
      end

      context "when a symbol is given" do
        let(:dynamic_rule) { :foo? }

        it { is_expected.to eq(:foo?) }
      end

      context "when a proc is given" do
        let(:dynamic_rule) { -> { true } }

        it { is_expected.to eq(dynamic_rule) }
      end
    end

    context "when the given dynamic rule is invalid" do
      [1, ["rule"], "", :"", Symbol, [], {}].each do |invalid_dynamic_rule|
        context "when '#{invalid_dynamic_rule}' is given" do
          let(:dynamic_rule) { invalid_dynamic_rule }

          it "raises an error" do
            expect { subject }.to raise_error(Rabarber::InvalidArgumentError, "Error")
          end
        end
      end
    end

    context "when no error and message are given" do
      subject { described_class.new(1).process }

      it "raises the default error with the default message" do
        expect { subject }.to raise_error(Rabarber::InvalidArgumentError, "Expected a symbol, a string, or a proc, got `1`")
      end
    end
  end
end
