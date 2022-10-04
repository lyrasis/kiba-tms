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
      # extend Tms::Mixins::Tableable
      module RolesMergedIn
        include Dry::Monads[:result]

        def self.extended(mod)
          self.set_treatment_mappings(mod)
          self.set_checkable(mod)
        end

        def gets_roles_merged_in?
          true
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
          else
            self.checkable_from_scratch(mod)
          end
        end
        private_class_method :set_checkable

        def self.set_treatment_mappings(mod)
          return if mod.respond_to?(:con_role_treatment_mappings)
          mod.module_eval(
            "setting :con_role_treatment_mappings, default: {}, reader: true"
          )
        end
        private_class_method :set_treatment_mappings
      end
    end
  end
end
