# frozen_string_literal: true

RSpec.describe Rabarber::Rule do
  describe "validations" do
    context "when action is invalid" do
      [1, ["index"], "", Symbol, {}, :""].each do |wrong_action_name|
        it "raises an error when '#{wrong_action_name}' is given as an action name" do
          expect { described_class.new(wrong_action_name, nil, nil, nil) }.to raise_error(
            Rabarber::InvalidArgumentError, "Action name must be a Symbol or a String"
          )
        end
      end
    end

    context "when roles are invalid" do
      [1, Symbol, "Admin", :"foo-bar", "", [""], ["admin "]].each do |wrong_roles|
        it "raises an error when '#{wrong_roles}' are given as roles" do
          expect { described_class.new(nil, wrong_roles, nil, nil) }.to raise_error(
            Rabarber::InvalidArgumentError,
            "Role names must be Symbols or Strings and may only contain lowercase letters, numbers and underscores"
          )
        end
      end
    end

    context "when dynamic rule is invalid" do
      [1, ["rule"], "", :"", Symbol, [], {}].each do |wrong_dynamic_rule|
        it "raises an error when '#{wrong_dynamic_rule}' is given as a dynamic rule" do
          expect { described_class.new(nil, nil, wrong_dynamic_rule, false) }.to raise_error(
            Rabarber::InvalidArgumentError,
            "Dynamic rule must be a Symbol, a String, or a Proc"
          )
        end
      end
    end
  end

  describe "#verify_access" do
    subject { rule.verify_access(:admin, DummyController, :index) }

    let(:rule) { described_class.new(:index, :admin, -> { true }, false) }

    context "if all conditions are met" do
      before do
        allow(rule).to receive(:action_accessible?).with(:index).and_return(true)
        allow(rule).to receive(:roles_permitted?).with(:admin).and_return(true)
        allow(rule).to receive(:dynamic_rule_followed?).with(DummyController).and_return(true)
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
          allow(rule).to receive(:dynamic_rule_followed?).with(DummyController).and_return([true, false].sample)
        end

        it "returns false" do
          expect(subject).to be false
        end
      end

      context "if roles are not permitted" do
        before do
          allow(rule).to receive(:action_accessible?).with(:index).and_return([true, false].sample)
          allow(rule).to receive(:roles_permitted?).with(:admin).and_return(false)
          allow(rule).to receive(:dynamic_rule_followed?).with(DummyController).and_return([true, false].sample)
        end

        it "returns false" do
          expect(subject).to be false
        end
      end

      context "if dynamic rule is not followed" do
        before do
          allow(rule).to receive(:action_accessible?).with(:index).and_return([true, false].sample)
          allow(rule).to receive(:roles_permitted?).with(:admin).and_return([true, false].sample)
          allow(rule).to receive(:dynamic_rule_followed?).with(DummyController).and_return(false)
        end

        it "returns false" do
          expect(subject).to be false
        end
      end
    end
  end

  describe "#action_accessible?" do
    subject { rule.action_accessible?(action_name) }

    let(:rule) { described_class.new(:index, [:admin], -> { true }, false) }

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

    let(:rule) { described_class.new(:index, roles, nil, nil) }

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

  describe "#dynamic_rule_followed?" do
    subject { rule.dynamic_rule_followed?(dynamic_rule_receiver) }

    let(:dynamic_rule_receiver) { double }
    let(:rule) { described_class.new(:index, :manager, dynamic_rule, is_negated) }

    context "dynamic rule is empty" do
      let(:dynamic_rule) { nil }
      let(:is_negated) { nil }

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "when dynamic rule is a proc" do
      before { allow(dynamic_rule_receiver).to receive(:params).and_return({ foo: "bar" }) }

      context "when is_negated is false" do
        let(:is_negated) { false }

        context "lambda returns true" do
          let(:dynamic_rule) { -> { params[:foo] == "bar" } }

          it "returns true" do
            expect(subject).to be true
          end
        end

        context "lambda returns false" do
          let(:dynamic_rule) { -> { params[:foo] == "bad" } }

          it "returns false" do
            expect(subject).to be false
          end
        end
      end

      context "when is_negated is true" do
        let(:is_negated) { true }

        context "lambda returns true" do
          let(:dynamic_rule) { -> { params[:foo] == "bar" } }

          it "returns false" do
            expect(subject).to be false
          end
        end

        context "lambda returns false" do
          let(:dynamic_rule) { -> { params[:foo] == "bad" } }

          it "returns true" do
            expect(subject).to be true
          end
        end
      end
    end

    context "when dynamic rule is a method name" do
      before do
        allow(dynamic_rule_receiver).to receive(:foo).and_return(true)
        allow(dynamic_rule_receiver).to receive(:bar).and_return(false)
      end

      context "when is_negated is false" do
        let(:is_negated) { false }

        context "method returns true" do
          let(:dynamic_rule) { :foo }

          it "returns true" do
            expect(subject).to be true
          end
        end

        context "method returns false" do
          let(:dynamic_rule) { :bar }

          it "returns false" do
            expect(subject).to be false
          end
        end
      end

      context "when is_negated is true" do
        let(:is_negated) { true }

        context "method returns true" do
          let(:dynamic_rule) { :foo }

          it "returns false" do
            expect(subject).to be false
          end
        end

        context "method returns false" do
          let(:dynamic_rule) { :bar }

          it "returns true" do
            expect(subject).to be true
          end
        end
      end
    end
  end
end
