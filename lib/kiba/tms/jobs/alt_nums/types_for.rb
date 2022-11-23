# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module TypesFor
          module_function

          def job(table:)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :alt_nums__types,
                destination: "alt_nums__types_for_#{table.filekey}".to_sym
              },
              transformer: xforms(table)
            )
          end

          def xforms(table)
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :tablename,
                value: table.tablename
              transform Delete::Fields, fields: :tablename
              transform Rename::Fields, fieldmap: {
                description: :number_type,
                desc_occs: :occurrences
              }
            end
          end
        end
      end
    end
  end
end
