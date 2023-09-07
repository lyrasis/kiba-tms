# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Transforms::Constituents::MergeDefaultAltName do
  subject(:xform) { described_class.new(alt_names: alt_names) }
  let(:result) { input.map { |row| xform.process(row) } }
  let(:alt_names) do
    {
      "1" => [{displayname: "a b", alphasort: "b a"}],
      "3" => []
    }
  end

  let(:input) do
    [
      {displayname: "a", alphasort: "b", defaultnameid: "1"},
      {displayname: "z y", alphasort: "y z", defaultnameid: "3"}
    ]
  end

  context "with preferred name field = displayname" do
    before do
      Tms::Constituents.config.preferred_name_field = :displayname
    end
    after { Tms::Constituents.reset_config }

    let(:expected) do
      [
        "a b",
        nil
      ]
    end

    it "transforms as expected" do
      expect(result.map { |row| row[:alt_displayname] }).to eq(expected)
    end
  end

  context "with preferred name field = alphasort" do
    before do
      Tms::Constituents.config.preferred_name_field = :alphasort
    end
    after { Tms::Constituents.reset_config }
    let(:expected) do
      [
        "b a",
        nil
      ]
    end

    it "transforms as expected" do
      expect(result.map { |row| row[:alt_alphasort] }).to eq(expected)
    end
  end
end
