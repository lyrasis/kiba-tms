# frozen_string_literal: true

require 'dry/monads'

module Kiba
  module Tms
    module Mixins
      # `Tms.finalize_config` gathers all configs for tables that are target
      #   tables of Tms::ConRefs. It then extends those config modules with
      #   this module.
      #
      # `Tms::Utils::InitialDependentConfigDeriver` uses
      #   `:respond_to(:merges_roles?` to select config modules on which to
      #   call `Tms::Services::RoleTreatmentDeriver`.
      #
      # ## Implementation details
      #
      # Modules/classes mixing this in must:
      #
      # extend Tms::Mixins::RolesMergedIn
      module RolesMergedIn
        include Dry::Monads[:result]

        def self.extended(mod)
          self.set_treatment_mappings(mod)
          self.set_checkable(mod)
          self.set_con_ref_field_rules(mod)
        end

        def gets_roles_merged_in?
          true
        end

        def con_ref_target_base_fields
          con_role_treatment_mappings.keys - %i[unmapped drop]
        end

        def fieldrules
          return nil unless con_ref_field_rules

          targets = con_ref_target_base_fields
          con_ref_field_rules[Tms.cspace_profile].select do |field, rules|
            targets.any?(field)
          end
        end

        def con_ref_suffixed_fields(field)
          fieldrules[field][:suffixes].map do |suffix|
            "#{field}#{suffix}".to_sym
          end
        end
        private :con_ref_suffixed_fields

        def con_ref_target_fields
          con_ref_target_base_fields.map{ |field| con_ref_suffixed_fields(field) }
            .flatten
        end

        def check_unmapped_role_terms
          meth = :con_role_treatment_mappings
          unless respond_to?(meth)
            return Failure(Tms::Data::DeriverFailure.new(
              mod: "#{name}.#{__callee__}",
              name: meth,
              sym: :missing_setting
            ))
          end
          unmapped = send(meth)[:unmapped]
          return nil if umapped.blank?

          Success(Tms::Data::ConfigSetting.new(
            mod:"#{name}.#{__callee__}",
            name: :unmapped_role_terms,
            value: unmapped.join(', ')
            ))
        end

        def self.checkable_as_needed(mod)
          existing = mod.checkable.dup
          self.checkable_from_scratch(mod)
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
          mod.module_eval(code)
        end
        private_class_method :checkable_from_scratch

        def self.set_checkable(mod)
          if mod.respond_to?(:checkable)
            self.checkable_as_needed(mod)
          else
            self.checkable_from_scratch(mod)
          end
        end
        private_class_method :set_checkable

        def self.set_treatment_mappings(mod)
          unless mod.respond_to?(:con_role_treatment_mappings)
          mod.module_eval(
            "setting :con_role_treatment_mappings, default: {}, reader: true"
          )
          end
        end
        private_class_method :set_treatment_mappings

        def self.set_con_ref_field_rules(mod)
          unless mod.respond_to?(:con_ref_field_rules)
            mod.module_eval(
              'setting :con_ref_field_rules, default: {}, reader: true'
            )
          end

          return if mod.send(:con_ref_field_rules).nil?

          if mod.send(:con_ref_field_rules).empty?
            warn("Need to set up :con_ref_field_rules for #{mod}")
          end
        end
        private_class_method :set_con_ref_field_rules
      end
    end
  end
end
