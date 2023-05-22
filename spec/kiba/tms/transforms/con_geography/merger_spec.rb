# frozen_string_literal: true

RSpec.describe Kiba::Tms::Transforms::ConGeography::Merger do
  subject(:xform) { described_class.new(**params) }
  let(:params) { {auth: auth, lookup: lookup} }
  let(:lookup_single) do
    {"1" => [
      {constituentid: "1", type: "birth", mergeable: "London"},
      {constituentid: "1", type: "death", mergeable: "Paris"}
    ]}
  end
  let(:lookup_multi) do
    {"1" => [
      {constituentid: "1", type: "birth", mergeable: "London"},
      {constituentid: "1", type: "birth", mergeable: "Londre"},
      {constituentid: "1", type: "birth", mergeable: "Londontown"},
      {constituentid: "1", type: nil, mergeable: "Variant birthplaces"},
      {constituentid: "1", type: "death", mergeable: "Paris"},
      {constituentid: "1", type: "death", mergeable: "Montmartre"},
      {constituentid: "1", type: "death", mergeable: "Madrid"},
      {constituentid: "1", type: nil, mergeable: "Disputed deathplaces"},
    ]}
  end
  let(:row) { {constituentid: "1"} }

  describe "#process" do
    let(:result) { xform.process(row) }

    context "with person" do
      let(:auth) { :person }

      context "with one lookup value per type" do
        let(:lookup) { lookup_single }

        it "produces expected row" do
          expected = {
            constituentid: "1",
            birthplace: "London",
            geo_birthnote: nil,
            deathplace: "Paris",
            geo_deathnote: nil,
            geo_note: nil
          }
          expect(result).to eq(expected)
        end
      end

      context "with multiple lookup values per type" do
        let(:lookup) { lookup_multi }

        it "produces expected row" do
          expected = {
            constituentid: "1",
            birthplace: "London",
            geo_birthnote: "Additional birth place: Londre%CR%"\
              "Additional birth place: Londontown",
            deathplace: "Paris",
            geo_deathnote: "Additional death place: Montmartre%CR%"\
              "Additional death place: Madrid",
            geo_note: "Variant birthplaces%CR%Disputed deathplaces"
          }
          expect(result).to eq(expected)
        end
      end
    end

    context "with org" do
      let(:auth) { :org }

      context "with one lookup value per type" do
        let(:lookup) { lookup_single }

        it "produces expected row" do
          expected = {
            constituentid: "1",
            foundingplace: "London",
            geo_foundingnote: nil,
            geo_dissolutionnote: "Dissolution place: Paris",
            geo_note: nil
          }
          expect(result).to eq(expected)
        end
      end

      context "with multiple lookup values per type" do
        let(:lookup) { lookup_multi }

        it "produces expected row" do
          expected = {
            constituentid: "1",
            foundingplace: "London",
            geo_foundingnote: "Additional founding place: Londre%CR%"\
              "Additional founding place: Londontown",
            geo_dissolutionnote: "Dissolution place: Paris%CR%"\
              "Additional dissolution place: Montmartre%CR%"\
              "Additional dissolution place: Madrid",
            geo_note: "Variant birthplaces%CR%Disputed deathplaces"
          }
          expect(result).to eq(expected)
        end
      end
    end
  end
end
