# frozen_string_literal: true

RSpec.describe Rabarber::Input::DynamicRule do
  describe "#process" do
    subject { described_class.new(dynamic_rule).process }

    context "when the given dynamic rule is valid" do
      context "when a string is given" do
        let(:dynamic_rule) { "foo?" }

        it { is_expected.to eq(:foo?) }
      end

      context "when a symbol is given" do
        let(:dynamic_rule) { :foo? }

        it { is_expected.to eq(:foo?) }
      end

      context "when nil is given" do
        let(:dynamic_rule) { nil }

        it { is_expected.to be_nil }
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
            expect { subject }.to raise_error(
              Rabarber::InvalidArgumentError,
              "Expected a symbol, a string, or a proc, got #{invalid_dynamic_rule.inspect}"
            )
          end
        end
      end
    end
  end
end
