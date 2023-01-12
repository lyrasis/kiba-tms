# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConRefs
        class Merger
          # @param into [Module]
          # @param keycolumn [Symbol]
          def initialize(into:, keycolumn:)
            @into = into
            @keycolumn = keycolumn
            @config = into.con_role_treatment_mappings
            @fieldrules = into.fieldrules
            @fields = into.con_ref_target_base_fields
            check_for_fields_without_rules
            if config.key?(:unmapped) && !config[:unmapped].empty?
              warn(
                "Unmapped role vals for #{into}: #{config[:unmapped].join(', ')}"
              )
            end
            @lookup = Tms.get_lookup(
              jobkey: "con_refs_for__#{into.filekey}".to_sym,
              column: :recordid
            )
            @xforms = build_xforms
          end

          def process(row)
            xforms.each{ |xform| xform.process(row) }
            row
          end

          private

          attr_reader :into, :keycolumn, :config, :fieldrules, :fields, :lookup,
            :xforms

          def add_note_to_fieldmap(base, suffix, rule)
            target = get_note_target(suffix, rule)
            return base unless target

            base.merge({target => :note})
          end

          def get_note_target(suffix, rule)
            target = "#{suffix}_note_target".to_sym
            rule[target]
          end

          def add_role_to_fieldmap(base, target, rule)
            return base unless rule[:merge_role]

            roletarget = "#{target}#{rule[:role_suffix]}".to_sym
            base.merge({roletarget => :role})
          end

          def build_fieldmap(field, suffix, rule, source)
            target = "#{field}#{suffix}".to_sym
            base = {target => source}
            role = add_role_to_fieldmap(base, target, rule)
            add_note_to_fieldmap(role, suffix, rule)
          end

          def build_rule_xforms(field, rule)
            rule[:suffixes].map{ |suff| build_xform(field, suff, rule) }
          end

          def build_xform(field, suffix, rule)
            source = suffix.start_with?('person') ? :person : :org
            fieldmap = build_fieldmap(field, suffix, rule, source)
            values = config[field]
            conditions = ->(_orig, rows) do
              rows.reject{ |row| row[source].blank? }
                .select{ |row| values.any?(row[:role]) }
            end

            Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: keycolumn,
              fieldmap: fieldmap,
              conditions: conditions,
              sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i),
              delim: Tms.delim,
              null_placeholder: Tms.nullvalue
            )
          end

          def build_xforms
            [
              fieldrules.map{ |field, rule| build_rule_xforms(field, rule) }
            ].flatten
              .compact
          end

          def check_for_fields_without_rules
            missing = fields - fieldrules.keys
            return if missing.empty?

            warn(
              "Add rules for fields to #{into} config: #{missing.join(', ')}"
            )
          end
        end
      end
    end
  end
end
