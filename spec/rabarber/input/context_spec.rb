# frozen_string_literal: true

RSpec.describe Rabarber::Input::Context do
  describe "#process" do
    subject { described_class.new(context).process }

    context "when the given context is valid" do
      context "when a class is given" do
        let(:context) { Project }

        it { is_expected.to eq(context_type: "Project", context_id: nil) }
      end

      context "when an instance of ActiveRecord::Base is given" do
        let(:context) { Project.create! }

        it { is_expected.to eq(context_type: "Project", context_id: context.id) }
      end

      context "when an instance of ActiveRecord::Base is given but not persisted" do
        let(:context) { Project.new }

        it "raises an error" do
          expect { subject }.to raise_error(
            Rabarber::InvalidArgumentError,
            "Expected a Class or an instance of ActiveRecord model, got #{context.inspect}"
          )
        end
      end

      context "when nil is given" do
        let(:context) { nil }

        it { is_expected.to eq(context_type: nil, context_id: nil) }
      end

      context "when the context is already processed" do
        let(:context) { { context_type: "Project", context_id: 1 } }

        it { is_expected.to eq(context_type: "Project", context_id: 1) }
      end
    end

    context "when the given context is invalid" do
      [1, ["context"], "context", "", :context, {}, :""].each do |invalid_context|
        context "when '#{invalid_context}' is given" do
          let(:context) { invalid_context }

          it "raises an error" do
            expect { subject }.to raise_error(
              Rabarber::InvalidArgumentError,
              "Expected a Class or an instance of ActiveRecord model, got #{invalid_context.inspect}"
            )
          end
        end
      end
    end
  end
end
