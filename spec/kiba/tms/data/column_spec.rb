# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Data::Column do
  subject(:klass){ described_class }
  module Tms
    module UnusedMod
      module_function
      def used?
        false
      end
    end

    module UsedMod
      module_function
      def used?
        true
      end
    end
  end

  class TableGetter
    def self.call(mod)
      Dry::Monads::Success([
        {title: "a"},
        {title: "b"},
        {title: "c"},
        {title: "a"},
        {title: "b"},
        {title: "d"},
      ].to_enum)
    end
  end

  describe ".initialize" do
    let(:result){ klass.new(**params) }

    context "with Module mod, Symbol field" do
      let(:params){ {mod: Tms::UsedMod, field: :title, table_getter: TableGetter} }

      it "works as expected" do
        expect(result.instance_variable_get(:@mod)).to eq(Tms::UsedMod)
        expect(result.instance_variable_get(:@field)).to eq(:title)
        expect(
          result.instance_variable_get(:@status)
        ).to be_a(Dry::Monads::Success)
      end
    end

    context "with String mod and field" do
      let(:params){ {mod: "UsedMod", field: "title", table_getter: TableGetter} }

      it "works as expected" do
        expect(result.instance_variable_get(:@mod)).to eq(Tms::UsedMod)
        expect(result.instance_variable_get(:@field)).to eq(:title)
        expect(
          result.instance_variable_get(:@status)
        ).to be_a(Dry::Monads::Success)
      end
    end

    context "with unused mod" do
      let(:params){ {mod: "UnusedMod", field: "title", table_getter: TableGetter} }

      it "works as expected" do
        expect(result.instance_variable_get(:@mod)).to eq(Tms::UnusedMod)
        expect(result.instance_variable_get(:@field)).to eq(:title)
        status = result.instance_variable_get(:@status)
        expect(status).to be_a(Dry::Monads::Failure)
        expect(status.failure).to eq(:table_not_used)
      end
    end

    context "with undefined mod" do
      let(:params){ {mod: "MissingMod", field: "title", table_getter: TableGetter} }

      it "works as expected" do
        expect(result.instance_variable_get(:@mod)).to be_nil
        expect(result.instance_variable_get(:@field)).to eq(:title)
        status = result.instance_variable_get(:@status)
        expect(status).to be_a(Dry::Monads::Failure)
        expect(status.failure).to be_a(NameError)
      end
    end
  end

  describe "#to_monad" do
    let(:result){ klass.new(**params).to_monad }

    context "with Module mod, Symbol field" do
      let(:params){ {mod: Tms::UsedMod, field: :title, table_getter: TableGetter} }

      it "is Success" do
        expect(result).to be_a(Dry::Monads::Success)
      end
    end

    context "with String mod and field" do
      let(:params){ {mod: "UsedMod", field: "title", table_getter: TableGetter} }

      it "is Success" do
        expect(result).to be_a(Dry::Monads::Success)
      end
    end

    context "with unused mod" do
      let(:params){ {mod: "UnusedMod", field: "title", table_getter: TableGetter} }

      it "works as expected" do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to eq(:table_not_used)
      end
    end

    context "with undefined mod" do
      let(:params){ {mod: "MissingMod", field: "title", table_getter: TableGetter} }

      it "works as expected" do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to be_a(NameError)
      end
    end
  end

  describe "#unique_values" do
    let(:result){ klass.new(**params).unique_values }

    context "with Module mod and existing Symbol field" do
      let(:params){ {mod: Tms::UsedMod, field: :title, table_getter: TableGetter} }

      it "is Success" do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(%w[a b c d])
      end
    end

    context "with String mod and non-existent field" do
      let(:params){ {mod: "UsedMod", field: "foo", table_getter: TableGetter} }

      it "is Success" do
        expect(result).to be_a(Dry::Monads::Success)
        expect(result.value!).to eq(%w[])
      end
    end

    context "with unused mod" do
      let(:params){ {mod: "UnusedMod", field: "title", table_getter: TableGetter} }

      it "works as expected" do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to eq(:table_not_used)
      end
    end

    context "with undefined mod" do
      let(:params){ {mod: "MissingMod", field: "title", table_getter: TableGetter} }

      it "works as expected" do
        expect(result).to be_a(Dry::Monads::Failure)
        expect(result.failure).to be_a(NameError)
      end
    end
  end
end
