# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      # Adds settings and methods for config modules where the values of some
      #   rows (determined by a type or code field) should be extracted for
      #   inclusion in a controlled vocabulary, while the values of other rows
      #   should not.
      #
      # Example: ConGeography rows with ConGeoCode value "Birthplace" should map
      #   to controlled if you are mapping that field to `birthPlace` and
      #   migrating into the :lhmc domain profile, but not
      #   other profiles. If you are mapping those values into the
      #   `suppliedBirthPlace` field, "Birthplace" would be a controlled type
      #   value in the anthro, bonsai, botgarden, core, fcart, and herbarium
      #   profiles.
      #
      # ## Implementation details
      #
      # Modules/classes mixing this in must:
      #
      # - Define `controlled_type_field` setting or method, returning name of
      #   field in which types are indicated. In the example above, this would
      #   be `:congeocode`
      # - `extend Tms::Mixins::ControllableByType`
      module ControllableByType
        def self.extended(mod)
          check_controlled_type_field_is_defined(mod)

          # Values in the `controlled_type_field` that will be mapped to
          #   authority controlled fields in CS. May be a list of one or more
          #   values, :all, or :none
          set_controlled_types(mod)

          # Lambda function passed to transforms in order to conditionally
          #   select only rows whose values will be mapped as authority terms.
          #   Returns true for all rows if `controlled_types` = :all, false for
          #   all rows if `controlled_types` = :none, or true/false per row,
          #   depending on whether row's `controlled_type_field` value is
          #   included in `controlled_types`
          #
          # If `controlled_types` is empty, returns a warning when used and
          #   acts like :none
          set_controlled_type_condition(mod)
        end

        def controllable_by_type?
          true
        end

        def self.check_controlled_type_field_is_defined(mod)
          unless mod.respond_to?(:controlled_type_field)
            fail UnconfiguredModuleError, "Define :controlled_type_field "\
              "setting or method in #{mod} before extending with #{name}"
          end
        end
        private_class_method :check_controlled_type_field_is_defined

        def self.set_controlled_type_condition(mod)
          return if mod.respond_to?(:controlled_type_condition)

          code = <<~CODE
            def controlled_type_condition
              ->(row) do
                types = #{mod}.controlled_types
                return true if types == :all
                return false if types == :none

                types.any?(row[:#{mod.controlled_type_field}])
              end
            end
          CODE
          mod.instance_eval(code)
        end
        private_class_method :set_controlled_type_condition

        def self.set_controlled_types(mod)
          return if mod.respond_to?(:controlled_types)

          code = <<~CODE
            setting :controlled_types,
              default: [],
              reader: true,
              constructor: ->(value) do
                if value == []
                  warn("WARNING: need to set `controlled_types` option "\
                  "for #{mod.name}")
                  :none
                else
                  value
                end
              end
          CODE
          mod.module_eval(code, __FILE__, __LINE__)
        end
        private_class_method :set_controlled_types
      end
    end
  end
end
