# frozen_string_literal: true

# TODO: implement

RSpec.describe Rabarber::Missing::Roles do
  subject { described_class.new(controller).handle }

  let(:callable_double) { instance_double(Proc) }

  before { allow(Rabarber::Configuration.instance).to receive(:when_roles_missing).and_return(callable_double) }

  context "when controller is not specified" do
    let(:controller) { nil }

    context "when role is missing" do
      context "in controller rules" do

      end

      context "in action rules" do

      end

      context "in both controller and action rules" do

      end
    end

    context "when role is not missing" do

    end
  end

  context "when controller is specified" do
    let(:controller) { DummyController }

    context "when role is missing" do
      context "in controller rules" do

      end

      context "in action rules" do

      end

      context "in both controller and action rules" do

      end
    end

    context "when role is not missing" do

    end

    context "when role is missing in another controller" do
      context "in controller rules" do

      end

      context "in action rules" do

      end

      context "in both controller and action rules" do

      end
    end
  end
end
