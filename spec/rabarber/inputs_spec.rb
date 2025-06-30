# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rabarber::Inputs do
  describe ".process for :boolean type" do
    subject { described_class.process(value, as: :boolean, error: Rabarber::Error, message: "Error") }

    context "when the given value is valid" do
      [true, false].each do |valid_value|
        context "when #{valid_value.inspect} is given" do
          let(:value) { valid_value }

          it { is_expected.to be valid_value }
        end
      end
    end

    context "when the given value is invalid" do
      [nil, 1, "foo", :foo, [], {}, User].each do |invalid_value|
        context "when '#{invalid_value.inspect}' is given" do
          let(:value) { invalid_value }

          it "raises an error" do
            expect { subject }.to raise_error(Rabarber::Error, "Error")
          end
        end
      end
    end
  end

  describe ".process for :string type" do
    subject { described_class.process(value, as: :string, error: Rabarber::Error, message: "Error") }

    context "when the given value is valid" do
      ["foo", "bar", "0", "test123"].each do |valid_value|
        context "when #{valid_value.inspect} is given" do
          let(:value) { valid_value }

          it { is_expected.to eq valid_value }
        end
      end
    end

    context "when the given value is invalid" do
      [nil, "", " ", [], {}, 123, :foo, false, true].each do |invalid_value|
        context "when #{invalid_value.inspect} is given" do
          let(:value) { invalid_value }

          it "raises an error" do
            expect { subject }.to raise_error(Rabarber::Error, "Error")
          end
        end
      end
    end
  end

  describe ".process for :symbol type" do
    subject { described_class.process(value, as: :symbol, error: Rabarber::Error, message: "Error") }

    context "when the given value is valid" do
      context "when a string is given" do
        let(:value) { "foo" }

        it { is_expected.to eq(:foo) }
      end

      context "when a symbol is given" do
        let(:value) { :bar }

        it { is_expected.to eq(:bar) }
      end
    end

    context "when the given value is invalid" do
      [nil, 1, [], {}, User, "", :""].each do |invalid_value|
        context "when '#{invalid_value}' is given" do
          let(:value) { invalid_value }

          it "raises an error" do
            expect { subject }.to raise_error(Rabarber::Error, "Error")
          end
        end
      end
    end
  end

  describe ".process for :role type" do
    subject { described_class.process(role, as: :role, error: Rabarber::InvalidArgumentError, message: "Error") }

    context "when the given role is valid" do
      context "when a symbol is given" do
        let(:role) { :admin }

        it { is_expected.to eq(:admin) }
      end

      context "when a string is given" do
        let(:role) { "manager" }

        it { is_expected.to eq(:manager) }
      end
    end

    context "when the given role is invalid" do
      [nil, "", 1, [""], Symbol, :"a-user", :Admin, "Admin", "admin ", { manager: true }].each do |invalid_role|
        context "when '#{invalid_role}' is given" do
          let(:role) { invalid_role }

          it "raises an error" do
            expect { subject }.to raise_error(
              Rabarber::InvalidArgumentError,
              "Error"
            )
          end
        end
      end
    end
  end

  describe ".process for :model type" do
    subject { described_class.process(value, as: :model, error: Rabarber::Error, message: "Error") }

    context "when the given value is valid" do
      ["User", "Project"].each do |valid_value|
        context "when #{valid_value} is given" do
          let(:value) { valid_value }
          let(:expected_value) { valid_value.to_s.constantize }

          it { is_expected.to be expected_value }
        end
      end
    end

    context "when the given value is invalid" do
      [true, :user, 1, nil, [User], User, "user"].each do |invalid_value|
        context "when '#{invalid_value}' is given" do
          let(:value) { invalid_value }

          it "raises an error" do
            expect { subject }.to raise_error(Rabarber::Error, "Error")
          end
        end
      end
    end
  end

  describe ".process for :roles type" do
    subject { described_class.process(roles, as: :roles, error: Rabarber::InvalidArgumentError, message: "Role names must be Symbols or Strings and may only contain lowercase letters, numbers, and underscores") }

    context "when the given roles are valid" do
      context "when an array of roles is given" do
        let(:roles) { [:admin, "manager"] }

        it { is_expected.to contain_exactly(:admin, :manager) }
      end

      context "when a single role is given" do
        let(:roles) { :admin }

        it { is_expected.to contain_exactly(:admin) }
      end

      context "when nil is given" do
        let(:roles) { nil }

        it { is_expected.to eq([]) }
      end
    end

    context "when the given role is invalid" do
      [1, [""], Symbol, :"a-user", :Admin, "Admin", "admin ", { manager: true }].each do |invalid_role|
        context "when '#{invalid_role}' is given" do
          let(:roles) { invalid_role }

          it "raises an error" do
            expect { subject }.to raise_error(
              Rabarber::InvalidArgumentError,
              "Role names must be Symbols or Strings and may only contain lowercase letters, numbers, and underscores"
            )
          end
        end
      end
    end
  end

  describe ".process for :dynamic_rule type" do
    subject { described_class.process(dynamic_rule, as: :dynamic_rule, error: Rabarber::InvalidArgumentError, message: "Dynamic rule must be a Symbol, a String, or a Proc") }

    context "when the given dynamic rule is valid" do
      context "when a string is given" do
        let(:dynamic_rule) { "foo?" }

        it { is_expected.to eq(:foo?) }
      end

      context "when a symbol is given" do
        let(:dynamic_rule) { :foo? }

        it { is_expected.to eq(:foo?) }
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
              "Dynamic rule must be a Symbol, a String, or a Proc"
            )
          end
        end
      end
    end
  end

  describe ".process for :context type" do
    subject { described_class.process(context, as: :role_context, error: Rabarber::InvalidArgumentError, message: "Context must be a Class or an instance of ActiveRecord model") }

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
              "Context must be a Class or an instance of ActiveRecord model"
            )
          end
        end
      end

      context "when an instance of ActiveRecord::Base is given but not persisted" do
        let(:context) { Project.new }

        it "raises an error" do
          expect { subject }.to raise_error(
            Rabarber::InvalidArgumentError,
            "Context must be a Class or an instance of ActiveRecord model"
          )
        end
      end
    end
  end

  describe ".process for :authorization_context type" do
    subject { described_class.process(context, as: :authorization_context, error: Rabarber::InvalidArgumentError, message: "Context must be a Class, an instance of ActiveRecord model, a Symbol, a String, or a Proc") }

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
            expect { subject }.to raise_error(
              Rabarber::InvalidArgumentError,
              "Context must be a Class, an instance of ActiveRecord model, a Symbol, a String, or a Proc"
            )
          end
        end
      end

      context "when an instance of ActiveRecord::Base is given but not persisted" do
        let(:context) { Project.new }

        it "raises an error" do
          expect { subject }.to raise_error(
            Rabarber::InvalidArgumentError,
            "Context must be a Class, an instance of ActiveRecord model, a Symbol, a String, or a Proc"
          )
        end
      end
    end
  end
end
