# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MultiTableMergeable
        module ForTable
          module_function

          def job(source:, dest:, targettable:, field: :tablename, xforms: nil)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: source,
                destination: dest
              },
              transformer: for_table_xforms(
                table: targettable,
                field: field,
                xforms: xforms
              )
            )
          end

          # @param table [String]
          # @param field [Symbol]
          # @param xforms [Array] of transform classes
          def for_table_xforms(table:, field: :tablename, xforms: nil)
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: field,
                value: table

              xforms.each { |xform| transform xform } if xforms

              transform Delete::Fields,
                fields: field
            end
          end
        end
      end
    end
  end
end
