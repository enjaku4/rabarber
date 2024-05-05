# frozen_string_literal: true

RSpec.describe Rabarber::Input::Context do
  describe "#process" do
    subject { described_class.new(context).process }

    context "when the given context is valid" do
      context "when a class is given" do
        let(:context) { Project }

        it { is_expected.to eq(context_type: Project, context_id: nil) }
      end

      context "when an instance of ActiveRecord::Base is given" do
        let(:context) { Project.create! }

        it { is_expected.to eq(context_type: Project, context_id: context.id) }
      end

      context "when nil is given" do
        let(:context) { nil }

        it { is_expected.to eq(context_type: nil, context_id: nil) }
      end
    end

    context "when the given context is invalid" do
      [1, ["context"], "context", "", :context, {}, :""].each do |invalid_context|
        let(:context) { invalid_context }

        it "raises an error when '#{invalid_context}' is given as an action name" do
          expect { subject }.to raise_error(
            Rabarber::InvalidArgumentError, "Context must be a Class or an instance of ActiveRecord::Base"
          )
        end
      end
    end
  end
end
