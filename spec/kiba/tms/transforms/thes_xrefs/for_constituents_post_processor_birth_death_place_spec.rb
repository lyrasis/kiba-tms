# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Layout/LineLength
RSpec.describe Kiba::Tms::Transforms::ThesXrefs::ForConstituentsPostProcessorBirthDeathPlace do
  # rubocop:enable Layout/LineLength

  subject { described_class.new(authtype: authtype, placetype: placetype) }

  describe "#process" do
    let(:basefield) { {} }
    let(:row) { basefield.merge(termfields) }
    let(:result) { subject.process(row) }

    let(:birthmulti) do
      {
        term_birth_founding_place_preferred: "b|c",
        term_birth_founding_place_used: "d|e",
        term_birth_founding_place_note: "f|%NULLVALUE%"
      }
    end
    let(:deathmulti) do
      {
        term_death_dissolution_place_preferred: "b|c",
        term_death_dissolution_place_used: "d|e",
        term_death_dissolution_place_note: "%NULLVALUE%|f"
      }
    end

    context "when authtype = :person" do
      let(:authtype) { :person }

      context "when placetype = :birth" do
        let(:placetype) { :birth }
        let(:termfields) { birthmulti }

        context "with no term" do
          let(:termfields) { {} }
          let(:expected) { {birthplace: nil, term_note_birthplace: nil} }

          it "returns expected row" do
            expect(result).to eq(expected)
          end
        end

        context "when not main field source" do
          let(:basefield) { {birthplace: "a"} }
          let(:expected) do
            {
              birthplace: "a",
              term_note_birthplace:
              "Additional birth place: d -- f#{Tms.notedelim}"\
                "Additional birth place: e"
            }
          end

          it "returns expected row" do
            expect(result).to eq(expected)
          end
        end

        context "when main field source" do
          let(:basefield) { {} }

          context "when main field authority controlled" do
            let(:expected) do
              {
                birthplace: "b",
                term_note_birthplace:
                "Birth place field value note: f#{Tms.notedelim}"\
                "Additional birth place: e"
              }
            end

            it "returns expected row" do
              Tms.config.cspace_profile = :lhmc
              expect(result).to eq(expected)
              Tms.reset_config
            end
          end

          context "when main field free text" do
            let(:expected) do
              {
                birthplace: "d -- f",
                term_note_birthplace:
                "Additional birth place: e"
              }
            end

            it "returns expected row" do
              expect(result).to eq(expected)
            end
          end
        end
      end

      context "when placetype = :death" do
        let(:placetype) { :death }
        let(:termfields) { deathmulti }

        context "with no term" do
          let(:termfields) { {} }
          let(:expected) { {deathplace: nil, term_note_deathplace: nil} }

          it "returns expected row" do
            expect(result).to eq(expected)
          end
        end

        context "when not main field source" do
          let(:basefield) { {deathplace: "a"} }
          let(:expected) do
            {
              deathplace: "a",
              term_note_deathplace:
              "Additional death place: d#{Tms.notedelim}"\
                "Additional death place: e -- f"
            }
          end

          it "returns expected row" do
            expect(result).to eq(expected)
          end
        end

        context "when main field source" do
          let(:basefield) { {} }

          context "when main field authority controlled" do
            let(:expected) do
              {
                deathplace: "b",
                term_note_deathplace:
                  "Additional death place: e -- f"
              }
            end

            it "returns expected row" do
              Tms.config.cspace_profile = :lhmc
              expect(result).to eq(expected)
              Tms.reset_config
            end
          end

          context "when main field free text" do
            let(:expected) do
              {
                deathplace: "d",
                term_note_deathplace:
                "Additional death place: e -- f"
              }
            end

            it "returns expected row" do
              expect(result).to eq(expected)
            end
          end
        end
      end
    end

    context "when authtype = :org" do
      let(:authtype) { :org }

      context "when placetype = :birth" do
        let(:placetype) { :birth }
        let(:termfields) { birthmulti }

        context "with no term" do
          let(:termfields) { {} }
          let(:expected) { {foundingplace: nil, term_note_foundingplace: nil} }

          it "returns expected row" do
            expect(result).to eq(expected)
          end
        end

        context "when not main field source" do
          let(:basefield) { {foundingplace: "a"} }
          let(:expected) do
            {
              foundingplace: "a",
              term_note_foundingplace:
              "Additional foundation place: d -- f#{Tms.notedelim}"\
                "Additional foundation place: e"
            }
          end

          it "returns expected row" do
            expect(result).to eq(expected)
          end
        end
      end

      context "when placetype = :death" do
        let(:placetype) { :death }
        let(:termfields) { deathmulti }

        context "with no term" do
          let(:termfields) { {} }
          let(:expected) { {term_note_dissolutionplace: nil} }

          it "returns expected row" do
            expect(result).to eq(expected)
          end
        end

        context "with terms" do
          let(:expected) do
            {
              term_note_dissolutionplace:
              "Dissolution place: d#{Tms.notedelim}"\
                "Dissolution place: e -- f"
            }
          end

          it "returns expected row" do
            expect(result).to eq(expected)
          end
        end
      end
    end
  end
end
