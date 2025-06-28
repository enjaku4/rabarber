# frozen_string_literal: true

RSpec.describe Rabarber::Input::Action do
  describe "#process" do
    subject { described_class.new(action).process }

    context "when the given action is valid" do
      context "when a string is given" do
        let(:action) { "index" }

        it { is_expected.to eq(:index) }
      end

      context "when a symbol is given" do
        let(:action) { :show }

        it { is_expected.to eq(:show) }
      end

      context "when nil is given" do
        let(:action) { nil }

        it { is_expected.to be_nil }
      end
    end

    context "when the given action is invalid" do
      [1, ["index"], "", Symbol, {}, :""].each do |invalid_action|
        context "when '#{invalid_action}' is given" do
          let(:action) { invalid_action }

          it "raises an error" do
            expect { subject }.to raise_error(
              Rabarber::InvalidArgumentError, "Expected a symbol or a string, got #{invalid_action.inspect}"
            )
          end
        end
      end
    end
  end
end
