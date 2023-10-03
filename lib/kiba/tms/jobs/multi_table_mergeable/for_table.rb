# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MultiTableMergeable
        module ForTable
          module_function

          def job(source:, dest:, targettable:, main_mod:, for_table_mod:,
            field: :tablename)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: source,
                destination: dest
              },
              transformer: get_xforms(targettable, field, main_mod,
                for_table_mod)
            )
          end

          def get_xforms(targettable, field, main_mod, mod)
            base = [base_xforms(table: targettable, field: field,
              main_mod: main_mod)]
            base << prepper_xforms(mod) if mod.prepper_xforms
            base << lookupkey_xforms(field, main_mod)
            base
          end

          # @param table [String]
          # @param field [Symbol]
          def base_xforms(table:, main_mod:, field: :tablename)
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: field,
                value: table
            end
          end

          # @param xforms [Array] of transform classes
          def prepper_xforms(mod)
            Kiba.job_segment do
              mod.prepper_xforms.each { |xform| transform xform }
            end
          end

          def lookupkey_xforms(field, main_mod)
            Kiba.job_segment do
              transform CombineValues::FromFieldsWithDelimiter,
                sources: [field, main_mod.type_field],
                target: :lookupkey,
                delim: " ",
                delete_sources: false

              transform Delete::Fields,
                fields: field
            end
          end
        end
      end
    end
  end
end
