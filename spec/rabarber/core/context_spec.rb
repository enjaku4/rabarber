# frozen_string_literal: true

RSpec.describe Rabarber::Core::Context do
  describe "#initialize" do
    subject { described_class.new(context, wrap: wrap) }

    context "when wrap is false" do
      let(:wrap) { false }
      let(:context) { Project.create! }

      it "processes the input context" do
        expect(Rabarber::Input::Context).to receive(:new).with(context).and_call_original
        expect(subject.context).to eq(context_type: "Project", context_id: context.id)
      end
    end

    context "when wrap is true" do
      let(:wrap) { true }
      let(:context) { { context_type: "Project", context_id: nil } }

      it "does not process the input context" do
        expect(Rabarber::Input::Context).not_to receive(:new)
        expect(subject.context).to eq(context)
      end
    end
  end

  describe "#to_h" do
    subject { described_class.new(context).to_h }

    let(:context) { Project.create! }

    it "returns the processed context" do
      expect(subject).to eq(context_type: "Project", context_id: context.id)
    end
  end

  describe "#to_s" do
    subject { described_class.new(context).to_s }

    context "when context is global" do
      let(:context) { nil }

      it "returns 'Global'" do
        expect(subject).to eq("Global")
      end
    end

    context "when context is a type" do
      let(:context) { Project }

      it "returns the context type" do
        expect(subject).to eq("Project")
      end
    end

    context "when context is an instance" do
      let(:context) { Project.create! }

      it "returns the context type and id" do
        expect(subject).to eq("Project##{context.id}")
      end
    end

    context "when context is unexpected" do
      let(:context) { 42 }

      before { allow_any_instance_of(Rabarber::Input::Context).to receive(:process).and_return(42) }

      it "raises an error" do
        expect { subject }.to raise_error("Unexpected context: 42")
      end
    end
  end
end
