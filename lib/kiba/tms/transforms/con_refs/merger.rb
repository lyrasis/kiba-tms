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
            @lookup = get_lookup
            @xforms = build_xforms
          end

          def process(row)
            xforms.each{ |xform| xform.process(row) }
            row
          end

          private

          attr_reader :into, :keycolumn, :config, :fieldrules, :fields, :lookup,
            :xforms

          def build_fieldmap(field, suffix, rule, source)
            target = "#{field}#{suffix}".to_sym
            result = {target => source}
            return result unless rule[:merge_role]

            roletarget = "#{target}#{rule[:role_suffix]}".to_sym
            result.merge({roletarget => :role})
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
            sorter = Lookup::RowSorter.new(on: :displayorder, as: :to_i)

            Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: keycolumn,
              fieldmap: fieldmap,
              conditions: conditions,
              sorter: sorter,
              delim: Tms.delim,
              null_placeholder: Tms.nullvalue
            )
          end

          def build_xforms
            fieldrules.map{ |field, rule| build_rule_xforms(field, rule) }
              .flatten
          end

          def check_for_fields_without_rules
            missing = fields - fieldrules.keys
            return if missing.empty?

            warn(
              "Add rules for fields to #{into} config: #{missing.join(', ')}"
            )
          end

          # def get_fieldrules
          #   targets = config.keys
          #   into.con_ref_field_rules[Tms.cspace_profile]
          #     .select do |field, rules|
          #       targets.any?(field)
          #     end
          # end

          def get_lookup
            jobkey = "con_refs_for__#{into.filekey}".to_sym
            reg = Tms.registry.resolve(jobkey)
            path = reg.path
            unless File.exist?(path)
              Kiba::Extend::Command::Run.job(jobkey)
            end
            Kiba::Extend::Utils::Lookup.csv_to_hash(
              file: path,
              keycolumn: :recordid
            )
          end
        end
      end
    end
  end
end
