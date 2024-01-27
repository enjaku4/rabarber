# frozen_string_literal: true

RSpec.describe Rabarber::Permissions do
  let(:permissions) { Class.new(described_class) }

  describe ".add" do
    let(:rule) { instance_double(Rabarber::Rule) }
    let(:dynamic_rule) { ->(foo) { foo } }

    context "when action is given" do
      before { allow(Rabarber::Rule).to receive(:new).with(:index, [:admin], :dynamic_rule, false).and_return(rule) }

      it "adds permissions to the action rules storage" do
        expect { permissions.add(DummyController, :index, [:admin], :dynamic_rule, false) }
          .to change { permissions.instance.storage[:action_rules] }
          .to({ DummyController => [rule] })
      end
    end

    context "when no action is given" do
      before { allow(Rabarber::Rule).to receive(:new).with(nil, [:admin, :manager], nil, nil).and_return(rule) }

      it "adds permissions to the controller rules storage" do
        expect { permissions.add(DummyController, nil, [:admin, :manager], nil, nil) }
          .to change { permissions.instance.storage[:controller_rules] }
          .to({ DummyController => rule })
      end
    end
  end

  describe ".controller_rules" do
    context "if controller rules exist" do
      before do
        permissions.add(DummyController, nil, [:admin], ->(foo) { foo }, :bar)
        permissions.add(DummyParentController, nil, [], nil, nil)
      end

      it "returns rules for controllers" do
        expect(permissions.controller_rules.keys).to contain_exactly(DummyController, DummyParentController)
      end
    end

    context "if controller rules don't exist" do
      it "returns an empty array" do
        expect(permissions.controller_rules.keys).to eq([])
      end
    end
  end

  describe ".action_rules" do
    context "if action rules exist" do
      before do
        permissions.add(DummyController, :index, [], nil, nil)
        permissions.add(DummyPagesController, :show, [:manager, :admin], -> { true }, :foo)
      end

      it "returns rules for actions" do
        expect(permissions.action_rules.keys).to contain_exactly(DummyController, DummyPagesController)
      end
    end

    context "if action rules don\'t exist" do
      it "returns an empty array" do
        expect(permissions.action_rules.keys).to eq([])
      end
    end
  end

  describe ".handle_missing_roles" do
    subject { permissions.handle_missing_roles(roles, "Controller", :index) }

    let(:callable_double) { instance_double(Proc) }

    before do
      Rabarber::Role.create!(name: :admin)
      allow(Rabarber::Configuration.instance).to receive(:when_roles_missing).and_return(callable_double)
    end

    context "when missing roles exist" do
      let(:roles) { [:admin, :manager] }

      it "calls when_roles_missing" do
        expect(callable_double).to receive(:call).with([:manager], "Controller#index")
        subject
      end
    end

    context "when missing roles don't exist" do
      let(:roles) { [:admin] }

      it "doesn't call when_roles_missing" do
        expect(callable_double).not_to receive(:call)
        subject
      end
    end
  end
end
