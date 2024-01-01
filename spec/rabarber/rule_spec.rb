# frozen_string_literal: true

RSpec.describe Rabarber::Rule do
  describe "validations" do
    context "when action is invalid" do
      [1, ["index"], Symbol, "index"].each do |wrong_action_name|
        it "raises an error when '#{wrong_action_name}' is given as an action name" do
          expect { described_class.new(wrong_action_name, nil, nil) }.to raise_error(
            Rabarber::InvalidArgumentError, "Action name must be a symbol"
          )
        end
      end
    end

    context "when roles are invalid" do
      [1, "admin", [:admin, "client"], ["admin"], Symbol, "Admin"].each do |wrong_roles|
        it "raises an error when '#{wrong_roles}' are given as roles" do
          expect { described_class.new(nil, wrong_roles, nil) }.to raise_error(
            Rabarber::InvalidArgumentError,
            "Role names must be symbols and may only contain lowercase letters, numbers and underscores"
          )
        end
      end
    end

    context "when custom rule is invalid" do
      [1, "rule", ["rule"], Symbol].each do |wrong_custom_rule|
        it "raises an error when '#{wrong_custom_rule}' is given as a custom rule" do
          expect { described_class.new(nil, nil, wrong_custom_rule) }.to raise_error(
            Rabarber::InvalidArgumentError,
            "Custom rule must be a symbol or a proc"
          )
        end
      end
    end
  end

  describe "#verify_access" do
    subject { rule.verify_access(:admin, DummyController, :index) }

    let(:rule) { described_class.new(:index, :admin, -> { true }) }

    context "if all conditions are met" do
      before do
        allow(rule).to receive(:action_accessible?).with(:index).and_return(true)
        allow(rule).to receive(:roles_permitted?).with(:admin).and_return(true)
        allow(rule).to receive(:custom_rule_followed?).with(DummyController).and_return(true)
      end

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "if at least one condition is not met" do
      context "if action is not accessible" do
        before do
          allow(rule).to receive(:action_accessible?).with(:index).and_return(false)
          allow(rule).to receive(:roles_permitted?).with(:admin).and_return([true, false].sample)
          allow(rule).to receive(:custom_rule_followed?).with(DummyController).and_return([true, false].sample)
        end

        it "returns false" do
          expect(subject).to be false
        end
      end

      context "if roles are not permitted" do
        before do
          allow(rule).to receive(:action_accessible?).with(:index).and_return([true, false].sample)
          allow(rule).to receive(:roles_permitted?).with(:admin).and_return(false)
          allow(rule).to receive(:custom_rule_followed?).with(DummyController).and_return([true, false].sample)
        end

        it "returns false" do
          expect(subject).to be false
        end
      end

      context "if custom rule is not followed" do
        before do
          allow(rule).to receive(:action_accessible?).with(:index).and_return([true, false].sample)
          allow(rule).to receive(:roles_permitted?).with(:admin).and_return([true, false].sample)
          allow(rule).to receive(:custom_rule_followed?).with(DummyController).and_return(false)
        end

        it "returns false" do
          expect(subject).to be false
        end
      end
    end
  end

  describe "#action_accessible?" do
    subject { rule.action_accessible?(action_name) }

    let(:rule) { described_class.new(:index, [:admin], -> { true }) }

    context "if action is accesible" do
      let(:action_name) { :index }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "if action is nil" do
      let(:action_name) { nil }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "if action is not accesible" do
      let(:action_name) { :show }

      it "returns false" do
        expect(subject).to be false
      end
    end
  end

  describe "#roles_permitted?" do
    subject { rule.roles_permitted?(user_roles) }

    let(:rule) { described_class.new(:index, roles, nil) }

    context "if roles are permitted" do
      let(:roles) { :admin }
      let(:user_roles) { [:manager, :admin] }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "if roles are empty" do
      let(:roles) { [] }

      context "if user is not required to have roles" do
        context "if user has roles" do
          let(:user_roles) { [:manager] }

          it "returns true" do
            expect(subject).to be true
          end
        end

        context "if user does not have roles" do
          let(:user_roles) { [] }

          it "returns true" do
            expect(subject).to be true
          end
        end
      end

      context "if user is required to have roles" do
        before { ::Rabarber::Configuration.instance.must_have_roles = true }

        context "if user has roles" do
          let(:user_roles) { [:manager] }

          it "returns true" do
            expect(subject).to be true
          end
        end

        context "if user does not have roles" do
          let(:user_roles) { [] }

          it "returns false" do
            expect(subject).to be false
          end
        end
      end
    end

    context "if roles are not permitted" do
      let(:roles) { :admin }
      let(:user_roles) { [:accountant, :manager] }

      it "returns false" do
        expect(subject).to be false
      end
    end
  end

  describe "#custom_rule_followed?" do
    subject { rule.custom_rule_followed?(custom_rule_receiver) }

    let(:custom_rule_receiver) { double }
    let(:rule) { described_class.new(:index, :manager, custom_rule) }

    context "custom rule is empty" do
      let(:custom_rule) { nil }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "when custom rule is a proc" do
      before { allow(custom_rule_receiver).to receive(:params).and_return({ foo: "bar" }) }

      context "custom rule is followed" do
        let(:custom_rule) { -> { params[:foo] == "bar" } }

        it "returns true" do
          expect(subject).to be true
        end
      end

      context "custom rule is not followed" do
        let(:custom_rule) { -> { params[:foo] == "bad" } }

        it "returns false" do
          expect(subject).to be false
        end
      end
    end

    context "when custom rule is a method name" do
      before do
        allow(custom_rule_receiver).to receive(:foo).and_return(true)
        allow(custom_rule_receiver).to receive(:bar).and_return(false)
      end

      context "custom rule is followed" do
        let(:custom_rule) { :foo }

        it "returns true" do
          expect(subject).to be true
        end
      end

      context "custom rule is not followed" do
        let(:custom_rule) { :bar }

        it "returns false" do
          expect(subject).to be false
        end
      end
    end
  end
end
