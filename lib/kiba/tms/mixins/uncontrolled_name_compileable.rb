# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      # ## Implementation details
      #
      # Modules/classes mixing this in must:
      #
      # extend Tms::Mixins::UncontrolledNameCompileable
      module UncontrolledNameCompileable
        def self.extended(mod)
          check_name_fields(mod)
        end

        def is_uncontrolled_name_compileable?
          true
        end

        def name_compile_dest_job_key
          "name_compile_from__#{filekey}".to_sym
        end

        def name_compile_source_job_key
          Tms::NameCompile.uncontrolled_name_source_tables[table_name]
        end

        def self.check_name_fields(mod)
          meth = :name_fields
          return if mod.respond_to?(meth)

          warn("Need to set up :#{meth} for #{mod}")
          mod.module_eval(
            "setting :#{meth}, default: [], reader: true", __FILE__, __LINE__
          )
        end
        private_class_method :check_name_fields
      end
    end
  end
end
