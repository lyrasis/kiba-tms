# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ThesXrefs
        class ForConstituentsPostProcessorGender < ForConstituentsPostProcessor
          # @param authtype [:org, :person]
          def initialize(authtype:)
            @authtype = authtype
            @eligiblefield = :term_gender
            @labelfield = :term_gender_label
            @notefield = :term_gender_note
            @sourcefields = [eligiblefield, labelfield, notefield]
            @maintarget = :gender
            @notetarget = :term_note_gender
            @specialprefixsuffix = "on Gender field value"
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

          attr_reader :eligiblefield, :labelfield, :notefield, :sourcefields,
            :notetarget, :maintarget, :specialprefixsuffix, :body_delim

          def do_processing(row)
            vals = get_split_field_vals(row, sourcefields)
            if authtype == :person
              do_person_processing(row, vals)
            else
              add_normal_notes(row, vals)
            end
            do_deletes(row)
            row[notetarget] = nil unless row.key?(notetarget)
          end

          def do_person_processing(row, vals)
            case vals[eligiblefield].length
            when 1
              do_singleval_person_processing(row, vals)
            else
              do_multival_person_processing(row, vals)
            end
          end

          def add_normal_notes(row, vals)
            vals[eligiblefield].each_with_index do |term, idx|
              add_normal_note(row, term, idx, vals)
            end
          end

          def do_singleval_person_processing(row, vals)
            row[maintarget] = vals[eligiblefield][0]
            add_field_note(row, vals)
          end

          def do_multival_person_processing(row, vals)
            final_vals = vals.compact
              .map { |field, arr| [field, arr.pop] }
              .to_h
              .transform_values { |val| [val] }
            add_normal_notes(row, vals)
            do_singleval_person_processing(row, final_vals)
          end

          def add_normal_note(row, term, idx, vals)
            prefix = build_prefix(vals[labelfield][idx])
            body = build_body(term, vals[notefield][idx])
            append_value(
              row,
              notetarget,
              labeled_value(prefix, body),
              Tms.notedelim
            )
          end

          def add_field_note(row, vals)
            body = vals[notefield][0]
            return if body == "%NULLVALUE%"

            prefix = build_prefix(vals[labelfield][0], :special)
            append_value(
              row,
              notetarget,
              labeled_value(prefix, body),
              Tms.notedelim
            )
          end

          def build_prefix(labelval, mode = :normal)
            return if labelval.blank?

            base = "#{labelval.capitalize} note"
            return base if mode == :normal

            "#{base} #{specialprefixsuffix}"
          end

          def passthrough(row)
            row[maintarget] = nil if authtype == :person
            row[notetarget] = nil
            do_deletes(row)
          end
        end
      end
    end
  end
end
