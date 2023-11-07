# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ThesXrefs
        class ForConstituentsPostProcessor
          include Tms::Transforms::ValueAppendable
          include Tms::Transforms::ValueCombiners
          # Subclasses should implement:
          #
          # - eligiblefield - field whose value is checked, and if blank,
          #   processing is skipped
          # - sourcefields
          #
          # If needing to check whether this will be a main field source:
          #
          # - priorityfields
          # @param authtype [:org, :person]
          def initialize(authtype:)
            @authtype = authtype
            @processors = {
              birth_founding_place:
              ForConstituentsPostProcessorBirthDeathPlace.new(
                authtype: authtype, placetype: :birth
              ),
              death_dissolution_place:
              ForConstituentsPostProcessorBirthDeathPlace.new(
                authtype: authtype, placetype: :death
              ),
              gender: ForConstituentsPostProcessorGender.new(
                authtype: authtype
              ),
              nationality: ForConstituentsPostProcessorNationality.new(
                authtype: authtype
              )
            }
            @treatments = @processors.keys.intersection(
              Tms::ThesXrefs.constituents_treatments_used
            )
          end

          def process(row)
            treatments.each do |treatment|
              processors[treatment].process(row)
            end
            row
          end

          private

          attr_reader :authtype, :processors, :treatments

          def eligible_for_processing?(row)
            true unless row[eligiblefield].blank?
          end

          # @return [true] if @priorityfields defined in subclass are all
          #   blank
          def main_field_source?(row)
            priorityfields.map { |field| row[field] }
              .all?(&:blank?)
          end

          def get_split_field_vals(row, fields)
            fields.map { |field| [field, row[field]&.split(Tms.delim)] }
              .to_h
          end

          def get_full_label(label, fallback)
            return fallback if label.blank?

            "#{label.capitalize} note"
          end

          def do_deletes(row)
            sourcefields.each { |field| row.delete(field) }
            row
          end
        end
      end
    end
  end
end
