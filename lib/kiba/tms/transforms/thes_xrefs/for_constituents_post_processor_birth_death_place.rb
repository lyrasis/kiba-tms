# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ThesXrefs
        class ForConstituentsPostProcessorBirthDeathPlace <
            ForConstituentsPostProcessor
          CONFIGS = {
            org: Tms::Orgs,
            person: Tms::Persons
          }

          # @param authtype [:org, :person]
          # @param placetype [:birth, :death]
          def initialize(authtype:, placetype:)
            @authtype = authtype
            @placetype = placetype
            @eligiblefield = "term_#{srcfield_insert}_place_used".to_sym
            @notefield = "term_#{srcfield_insert}_place_note".to_sym
            @preffield = "term_#{srcfield_insert}_place_preferred".to_sym
            @sourcefields = [eligiblefield, notefield, preffield]
            @maintarget = "#{place_modifier}place".to_sym
            @priorityfields = [maintarget, "geog_#{maintarget}".to_sym]
            @notetarget = "term_note_#{maintarget}".to_sym
            @body_delim = " -- "
            @controlled = set_controlled
          end

          def process(row)
            if eligible_for_processing?(row)
              do_processing(row)
              finalize(row)
            else
              finalize(row)
            end
            row
          end

          private

          attr_reader :placetype, :eligiblefield, :notefield, :preffield,
            :sourcefields, :priorityfields, :maintarget, :notetarget,
            :body_delim, :controlled

          def do_processing(row)
            vals = get_split_field_vals(row, sourcefields)
            set_main_values(row, vals) if priority?(row)
            add_place_notes(row, vals)
          end

          def set_main_values(row, vals)
            firstvals = vals.map { |field, arr| [field, arr.shift] }
              .to_h
            if controlled
              set_controlled_main_field_and_note(row, firstvals)
            else
              set_freetext_main_field(row, firstvals)
            end
          end

          def set_controlled_main_field_and_note(row, firstvals)
            row[maintarget] = derive_main_value(firstvals)
            noteval = firstvals[notefield]
            return if noteval.blank? || noteval == "%NULLVALUE%"

            set_main_field_note(row, noteval)
          end

          def set_freetext_main_field(row, firstvals)
            row[maintarget] = derive_main_value(firstvals)
          end

          def set_main_field_note(row, noteval)
            prefix = "#{field_display_name} field value note"
            append_value(
              row,
              notetarget,
              labeled_value(prefix, noteval),
              Tms.notedelim
            )
          end

          def derive_main_value(firstvals)
            return firstvals[preffield] if controlled

            build_body(firstvals[eligiblefield], firstvals[notefield])
          end

          def add_place_notes(row, vals, subsequent: true)
            subsequent = false if dissolution?
            vals[eligiblefield].each_with_index do |term, idx|
              add_place_note(row, term, idx, vals, subsequent)
            end
          end

          def add_place_note(row, term, idx, vals, subsequent)
            prefix = place_note_prefix(subsequent)
            body = build_body(term, vals[notefield][idx])
            append_value(
              row,
              notetarget,
              labeled_value(prefix, body),
              Tms.notedelim
            )
          end

          def place_note_prefix(subsequent)
            display = field_display_name
            base = subsequent ? display.downcase : display
            prefix = subsequent ? "Additional" : ""
            safe_join(vals: [prefix, base], delim: " ")
          end

          def srcfield_insert
            return "birth_founding" if placetype == :birth

            "death_dissolution"
          end

          def field_display_name
            modifier = place_modifier.to_s
            display = (modifier == "founding") ? "foundation" : modifier
            "#{display.capitalize} place"
          end

          def place_modifier
            return placetype if authtype == :person

            (placetype == :birth) ? :founding : :dissolution
          end

          def priority?(row)
            return false if dissolution?

            main_field_source?(row)
          end

          def dissolution?
            authtype == :org && placetype == :death
          end

          def finalize(row)
            row[maintarget] = nil unless dissolution? || row.key?(maintarget)
            row[notetarget] = nil unless row.key?(notetarget)
            do_deletes(row)
          end

          def set_controlled
            return false if dissolution?

            meth = "#{maintarget}_controlled?".to_sym
            typeconfig = CONFIGS[authtype]
            return false unless typeconfig.respond_to?(meth)

            typeconfig.send(meth)
          end
        end
      end
    end
  end
end
