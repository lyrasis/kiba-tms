# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MultiTableMergeable
        module ForTable
          module_function

          def job(source:, dest:, targettable:, for_table_mod:,
            field: :tablename)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: source,
                destination: dest
              },
              transformer: get_xforms(targettable, field, for_table_mod)
            )
          end

          def get_xforms(targettable, field, mod)
            base = [base_xforms(table: targettable, field: field)]
            base << prepper_xforms(mod) if mod.prepper_xforms
            base
          end

          # @param table [String]
          # @param field [Symbol]
          def base_xforms(table:, field: :tablename)
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: field,
                value: table

              transform Delete::Fields,
                fields: field
            end
          end

          # @param xforms [Array] of transform classes
          def prepper_xforms(mod)
            Kiba.job_segment do
              mod.prepper_xforms.each { |xform| transform xform }
            end
          end
        end
      end
    end
  end
end
