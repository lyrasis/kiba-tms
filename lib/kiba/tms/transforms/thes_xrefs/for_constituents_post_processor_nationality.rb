# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ThesXrefs
        class ForConstituentsPostProcessorNationality <
            ForConstituentsPostProcessor
          # @param authtype [:org, :person]
          def initialize(authtype:)
            @authtype = authtype
            @eligiblefield = :term_nationality
            @labelfield = :term_nationality_label
            @notefield = :term_nationality_note
            @priorityfields = %i[nationality geog_nationality]
            @sourcefields = [eligiblefield, labelfield, notefield]
            @maintarget = :nationality
            @notetarget = :term_note_nationality
            @body_delim = " -- "
          end

          def process(row)
            if eligible_for_processing?(row)
              do_processing(row)
            else
              passthrough(row)
            end
            row
          end

          private

          attr_reader :eligiblefield, :labelfield, :notefield, :priorityfields,
            :maintarget, :sourcefields, :notetarget, :body_delim

          def do_processing(row)
            vals = get_split_field_vals(row, sourcefields)
            if authtype == :person && main_field_source?(row)
              set_main_field(row, vals)
            end
            row[notetarget] = map_all_to_note(vals)
            do_deletes(row)
          end

          def set_main_field(row, vals)
            firstvals = vals.map { |field, arr| [field, arr.shift] }
              .to_h
            row[maintarget] = build_body(
              firstvals[eligiblefield],
              firstvals[notefield]
            )
          end

          def map_all_to_note(vals)
            return if vals.values.all?(&:empty?)

            vals[eligiblefield].map.with_index { |val, idx|
              map_to_note(val, vals[labelfield][idx], vals[notefield][idx])
            }.join(Tms.notedelim)
          end

          def map_to_note(term, label, note)
            labeled_value(
              get_full_label(label, "Nationality note"),
              build_body(term, note)
            )
          end

          def passthrough(row)
            row[notetarget] = nil
            do_deletes(row)
          end
        end
      end
    end
  end
end
