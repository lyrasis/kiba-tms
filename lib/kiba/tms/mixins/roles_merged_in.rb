# frozen_string_literal: true

require "dry/monads"

module Kiba
  module Tms
    module Mixins
      # `Tms.finalize_config` gathers all configs for tables that are target
      #   tables of Tms::ConRefs. It then extends those config modules with
      #   this module.
      #
      # `Tms::Utils::InitialDependentConfigDeriver` uses
      #   `:respond_to(:merges_roles?)` to select config modules on which to
      #   call `Tms::Services::RoleTreatmentDeriver`.
      #
      # ## Implementation details
      #
      # This module is mixed into all config ConRefs target tables'
      #   config modules by Tms::Utils::ConRefTargetExtender in
      #   Tms.meta_config.
      #
      # Modules/classes mixing this in must:
      #
      # extend Tms::Mixins::RolesMergedIn
      module RolesMergedIn
        include Dry::Monads[:result]

        def self.extended(mod)
          set_treatment_mappings(mod)
          set_checkable(mod)
          set_con_ref_name_merge_rules(mod)
          # Adds con_ref_fieldrules_override config setting, which can be used
          #   to override rules for one or more target fields in a specific
          #   migration project. To change `owner/note_fields`, you need to
          #   include the entire `owner` field rule hash, updated as needed
          #   for your project
          set_con_ref_name_merge_rules_override(mod)
        end

        def gets_roles_merged_in?
          true
        end

        def con_ref_target_base_fields
          con_ref_role_to_field_mapping.keys - %i[unmapped drop]
        end

        def fieldrules
          return nil unless con_ref_name_merge_rules

          targets = con_ref_target_base_fields
          base = con_ref_name_merge_rules[Tms.cspace_profile]
            .select do |field, rules|
              targets.any?(field)
            end
          return base if con_ref_name_merge_rules_override.empty?

          base.merge(con_ref_name_merge_rules_override)
        end

        def con_ref_suffixed_fields(field)
          fieldrules[field][:suffixes].map do |suffix|
            "#{field}#{suffix}".to_sym
          end
        end
        private :con_ref_suffixed_fields

        def con_ref_target_fields
          con_ref_target_base_fields.map { |field|
            con_ref_suffixed_fields(field)
          }
            .flatten
        end

        def check_unmapped_role_terms
          meth = :con_ref_role_to_field_mapping
          unless respond_to?(meth)
            return Failure(Tms::Data::DeriverFailure.new(
              mod: "#{name}.#{__callee__}",
              name: meth,
              sym: :missing_setting
            ))
          end
          unmapped = send(meth)[:unmapped]
          return nil if unmapped.blank?

          Success(Tms::Data::ConfigSetting.new(
            mod: "#{name}.#{__callee__}",
            name: :unmapped_role_terms,
            value: unmapped.join(", ")
          ))
        end

        def self.checkable_as_needed(mod)
          existing = mod.checkable.dup
          checkable_from_scratch(mod)
          combined = mod.checkable.merge(existing)
          mod.config.checkable = combined
        end
        private_class_method :checkable_as_needed

        def self.checkable_from_scratch(mod)
          code = <<~CODE
            setting :checkable, default: {
              unmapped_role_terms: Proc.new{
                check_unmapped_role_terms
              }
            },
            reader: true
          CODE
          mod.module_eval(code, __FILE__, __LINE__)
        end
        private_class_method :checkable_from_scratch

        def self.set_checkable(mod)
          if mod.respond_to?(:checkable)
            checkable_as_needed(mod)
          else
            checkable_from_scratch(mod)
          end
        end
        private_class_method :set_checkable

        def self.set_treatment_mappings(mod)
          unless mod.respond_to?(:con_ref_role_to_field_mapping)
            mod.module_eval(
              "setting :con_ref_role_to_field_mapping, "\
                "default: {}, reader: true", __FILE__, __LINE__ - 1
            )
          end
        end
        private_class_method :set_treatment_mappings

        def self.set_con_ref_name_merge_rules(mod)
          unless mod.respond_to?(:con_ref_name_merge_rules)
            mod.module_eval(
              "setting :con_ref_name_merge_rules, "\
                "default: {}, reader: true", __FILE__, __LINE__ - 1
            )
          end

          return if mod.send(:con_ref_name_merge_rules).nil?

          if mod.send(:con_ref_name_merge_rules).empty?
            warn("Need to set up :con_ref_name_merge_rules for #{mod}")
          end
        end
        private_class_method :set_con_ref_name_merge_rules

        def self.set_con_ref_name_merge_rules_override(mod)
          unless mod.respond_to?(:con_ref_name_merge_rules_override)
            mod.module_eval(
              "setting :con_ref_name_merge_rules_override, "\
                "default: {}, "\
                "reader: true", __FILE__, __LINE__ - 2
            )
          end
        end
        private_class_method :set_con_ref_name_merge_rules_override
      end
    end
  end
end
