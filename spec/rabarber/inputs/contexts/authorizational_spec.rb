# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rabarber::Inputs::Contexts::Authorizational do
  describe "#resolve" do
    subject { described_class.new(context, error: Rabarber::InvalidArgumentError, message: "Error").resolve }

    context "when the given context is valid" do
      context "when a class is given" do
        let(:context) { Project }

        it { is_expected.to eq(context_type: "Project", context_id: nil) }
      end

      context "when an instance of ActiveRecord::Base is given" do
        let(:context) { Project.create! }

        it { is_expected.to eq(context_type: "Project", context_id: context.id) }
      end

      context "when nil is given" do
        let(:context) { nil }

        it { is_expected.to eq(context_type: nil, context_id: nil) }
      end

      context "when a string is given" do
        let(:context) { "project" }

        it { is_expected.to eq(:project) }
      end

      context "when a symbol is given" do
        let(:context) { :project }

        it { is_expected.to eq(:project) }
      end

      context "when a proc is given" do
        let(:context) { -> { Project } }

        it { is_expected.to eq(context) }
      end
    end

    context "when the given context is invalid" do
      [1, ["context"], "", {}, :""].each do |invalid_context|
        context "when '#{invalid_context}' is given" do
          let(:context) { invalid_context }

          it "raises an error" do
            expect { subject }.to raise_error(Rabarber::InvalidArgumentError, "Error")
          end
        end
      end

      context "when an instance of ActiveRecord::Base is given but not persisted" do
        let(:context) { Project.new }

        it "raises an error" do
          expect { subject }.to raise_error(Rabarber::InvalidArgumentError, "Error")
        end
      end
    end
  end
end
