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
      {constituentid: "1", type: nil, mergeable: "Disputed deathplaces"}
    ]}
  end
  let(:row) { {constituentid: "1", nationality: "English"} }

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
            geo_note: nil,
            nationality: "English"
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
            geo_birthnote: "Additional birth place: Londre#{Tms.notedelim}"\
              "Additional birth place: Londontown",
            deathplace: "Paris",
            geo_deathnote: "Additional death place: Montmartre#{Tms.notedelim}"\
              "Additional death place: Madrid",
            geo_note: "Variant birthplaces#{Tms.notedelim}Disputed deathplaces",
            nationality: "English"
          }
          expect(result).to eq(expected)
        end
      end
    end

    context "with org" do
      let(:auth) { :org }

      context "with no lookup values" do
        let(:lookup) { [] }

        it "produces expected row" do
          expected = {
            constituentid: "1",
            foundingplace: "English",
            geo_foundingnote: nil,
            geo_dissolutionnote: nil,
            geo_note: nil
          }
          expect(result).to eq(expected)
        end

        context "with :foundingplace_handling = congeo_only" do
          before {
            Kiba::Tms::Orgs.config.foundingplace_handling = :congeo_only
          }
          after { Kiba::Tms::Orgs.reset_config }
          it "produces expected row" do
            expected = {
              constituentid: "1",
              foundingplace: nil,
              geo_foundingnote: "Nationality: English",
              geo_dissolutionnote: nil,
              geo_note: nil
            }
            expect(result).to eq(expected)
          end
        end

        context "with :foundingplace_handling = nationality_only" do
          before do
            Kiba::Tms::Orgs.config.foundingplace_handling = :nationality_only
          end
          after { Kiba::Tms::Orgs.reset_config }
          it "produces expected row" do
            expected = {
              constituentid: "1",
              foundingplace: "English",
              geo_foundingnote: nil,
              geo_dissolutionnote: nil,
              geo_note: nil
            }
            expect(result).to eq(expected)
          end
        end
      end

      context "with one lookup value per type" do
        let(:lookup) { lookup_single }

        it "produces expected row" do
          expected = {
            constituentid: "1",
            foundingplace: "London",
            geo_foundingnote: "Nationality: English",
            geo_dissolutionnote: "Dissolution place: Paris",
            geo_note: nil
          }
          expect(result).to eq(expected)
        end

        context "with :foundingplace_handling = congeo_only" do
          before {
            Kiba::Tms::Orgs.config.foundingplace_handling = :congeo_only
          }
          after { Kiba::Tms::Orgs.reset_config }
          it "produces expected row" do
            expected = {
              constituentid: "1",
              foundingplace: "London",
              geo_foundingnote: "Nationality: English",
              geo_dissolutionnote: "Dissolution place: Paris",
              geo_note: nil
            }
            expect(result).to eq(expected)
          end
        end

        context "with :foundingplace_handling = nationality_only" do
          before do
            Kiba::Tms::Orgs.config.foundingplace_handling = :nationality_only
          end
          after { Kiba::Tms::Orgs.reset_config }
          it "produces expected row" do
            expected = {
              constituentid: "1",
              foundingplace: "English",
              geo_foundingnote: "Founding place: London",
              geo_dissolutionnote: "Dissolution place: Paris",
              geo_note: nil
            }
            expect(result).to eq(expected)
          end
        end
      end

      context "with multiple lookup values per type" do
        let(:lookup) { lookup_multi }

        it "produces expected row" do
          expected = {
            constituentid: "1",
            foundingplace: "London",
            geo_foundingnote: "Additional founding place: Londre#{Tms.notedelim}"\
              "Additional founding place: Londontown#{Tms.notedelim}"\
              "Nationality: English",
            geo_dissolutionnote: "Dissolution place: Paris#{Tms.notedelim}"\
              "Additional dissolution place: Montmartre#{Tms.notedelim}"\
              "Additional dissolution place: Madrid",
            geo_note: "Variant birthplaces#{Tms.notedelim}Disputed deathplaces"
          }
          expect(result).to eq(expected)
        end

        context "with :foundingplace_handling = congeo_only" do
          before {
            Kiba::Tms::Orgs.config.foundingplace_handling = :congeo_only
          }
          after { Kiba::Tms::Orgs.reset_config }

          it "produces expected row" do
            expected = {
              constituentid: "1",
              foundingplace: "London",
              geo_foundingnote: "Additional founding place: Londre#{Tms.notedelim}"\
                "Additional founding place: Londontown#{Tms.notedelim}"\
                "Nationality: English",
              geo_dissolutionnote: "Dissolution place: Paris#{Tms.notedelim}"\
                "Additional dissolution place: Montmartre#{Tms.notedelim}"\
                "Additional dissolution place: Madrid",
              geo_note: "Variant birthplaces#{Tms.notedelim}Disputed deathplaces"
            }
            expect(result).to eq(expected)
          end
        end

        context "with :foundingplace_handling = nationality_only" do
          before do
            Kiba::Tms::Orgs.config.foundingplace_handling = :nationality_only
          end
          after { Kiba::Tms::Orgs.reset_config }

          it "produces expected row" do
            expected = {
              constituentid: "1",
              foundingplace: "English",
              geo_foundingnote: "Founding place: London#{Tms.notedelim}"\
                "Additional founding place: Londre#{Tms.notedelim}"\
                "Additional founding place: Londontown",
              geo_dissolutionnote: "Dissolution place: Paris#{Tms.notedelim}"\
                "Additional dissolution place: Montmartre#{Tms.notedelim}"\
                "Additional dissolution place: Madrid",
              geo_note: "Variant birthplaces#{Tms.notedelim}Disputed deathplaces"
            }
            expect(result).to eq(expected)
          end
        end
      end

      context "with no nationality value and multiple lookup values per type" do
        let(:row) { {constituentid: "1", nationality: nil} }
        let(:lookup) { lookup_multi }

        it "produces expected row" do
          expected = {
            constituentid: "1",
            foundingplace: "London",
            geo_foundingnote: "Additional founding place: Londre#{Tms.notedelim}"\
              "Additional founding place: Londontown",
            geo_dissolutionnote: "Dissolution place: Paris#{Tms.notedelim}"\
              "Additional dissolution place: Montmartre#{Tms.notedelim}"\
              "Additional dissolution place: Madrid",
            geo_note: "Variant birthplaces#{Tms.notedelim}Disputed deathplaces"
          }
          expect(result).to eq(expected)
        end

        context "with :foundingplace_handling = congeo_only" do
          before {
            Kiba::Tms::Orgs.config.foundingplace_handling = :congeo_only
          }
          after { Kiba::Tms::Orgs.reset_config }

          it "produces expected row" do
            expected = {
              constituentid: "1",
              foundingplace: "London",
              geo_foundingnote: "Additional founding place: Londre#{Tms.notedelim}"\
                "Additional founding place: Londontown",
              geo_dissolutionnote: "Dissolution place: Paris#{Tms.notedelim}"\
                "Additional dissolution place: Montmartre#{Tms.notedelim}"\
                "Additional dissolution place: Madrid",
              geo_note: "Variant birthplaces#{Tms.notedelim}Disputed deathplaces"
            }
            expect(result).to eq(expected)
          end
        end

        context "with :foundingplace_handling = nationality_only" do
          before do
            Kiba::Tms::Orgs.config.foundingplace_handling = :nationality_only
          end
          after { Kiba::Tms::Orgs.reset_config }

          it "produces expected row" do
            expected = {
              constituentid: "1",
              foundingplace: nil,
              geo_foundingnote: "Founding place: London#{Tms.notedelim}"\
                "Additional founding place: Londre#{Tms.notedelim}"\
                "Additional founding place: Londontown",
              geo_dissolutionnote: "Dissolution place: Paris#{Tms.notedelim}"\
                "Additional dissolution place: Montmartre#{Tms.notedelim}"\
                "Additional dissolution place: Madrid",
              geo_note: "Variant birthplaces#{Tms.notedelim}Disputed deathplaces"
            }
            expect(result).to eq(expected)
          end
        end
      end
    end
  end
end
