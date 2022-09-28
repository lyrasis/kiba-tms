# frozen_string_literal: true

require 'csv'

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
        def gets_roles_merged_in?
          true
        end
      end
    end
  end
end
