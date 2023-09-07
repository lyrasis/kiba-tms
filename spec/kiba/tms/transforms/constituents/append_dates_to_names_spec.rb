# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Transforms::Constituents::AppendDatesToNames do
  subject(:xform) { described_class.new }
  let(:result) { input.map { |row| xform.process(row) } }
  let(:input) do
    [
      {contype: "Person", displayname: "Ann B.",
       alphasort: "Ann B.", birth_foundation_date: "1901",
       death_dissolution_date: "1929"},
      {contype: "Person", displayname: "Ann C.",
       alphasort: "Ann C.", birth_foundation_date: "1902",
       death_dissolution_date: ""},
      {contype: "Person", displayname: "Ann D.",
       alphasort: "Ann D.", birth_foundation_date: "",
       death_dissolution_date: "1930"},
      {contype: "Person", displayname: "Ann E.",
       alphasort: "Ann E.", birth_foundation_date: "",
       death_dissolution_date: ""},
      {contype: "Organization", displayname: "Foo",
       alphasort: "Foo", birth_foundation_date: "1901",
       death_dissolution_date: "1929"},
      {contype: "Organization", displayname: "Bar",
       alphasort: "Bar", birth_foundation_date: "1902",
       death_dissolution_date: ""},
      {contype: "Organization", displayname: "Baz",
       alphasort: "Baz", birth_foundation_date: "",
       death_dissolution_date: "1930"},
      {contype: "Organization", displayname: "Bam",
       alphasort: "Bam", birth_foundation_date: "",
       death_dissolution_date: ""},
      {contype: "Person", displayname: "Ann",
       alphasort: "", birth_foundation_date: "1901",
       death_dissolution_date: "1929"},
      {contype: "Person", displayname: "Ann",
       alphasort: nil, birth_foundation_date: "1901",
       death_dissolution_date: "1929"}
    ]
  end

  context "when append to types = none" do
    before { Kiba::Tms::Constituents.config.date_append_to_type = :none }
    after { Tms::Constituents.reset_config }

    it "passes rows through unaltered" do
      expect(result).to eq(input)
    end
  end

  context "when append to types = all" do
    before { Kiba::Tms::Constituents.config.date_append_to_type = :all }
    after { Tms::Constituents.reset_config }

    let(:expected) do
      [
        "Ann B., (1901 - 1929)",
        "Ann C., (1902 -)",
        "Ann D., (- 1930)",
        "Ann E.",
        "Foo, (1901 - 1929)",
        "Bar, (1902 -)",
        "Baz, (- 1930)",
        "Bam",
        "",
        nil
      ]
    end

    it "transforms as expected" do
      name = Tms::Constituents.preferred_name_field
      expect(result.map { |row| row[name] }).to eq(expected)
    end
  end

  context "when append to types = Individual" do
    before { Kiba::Tms::Constituents.config.date_append_to_type = :person }
    after { Tms::Constituents.reset_config }

    let(:expected) do
      [
        "Ann B., (1901 - 1929)",
        "Ann C., (1902 -)",
        "Ann D., (- 1930)",
        "Ann E.",
        "Foo",
        "Bar",
        "Baz",
        "Bam",
        "",
        nil
      ]
    end

    it "transforms as expected" do
      name = Tms::Constituents.preferred_name_field
      expect(result.map { |row| row[name] }).to eq(expected)
    end
  end
end
