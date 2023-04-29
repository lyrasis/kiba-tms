# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module Types
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :alt_nums__description_occs,
                destination: :alt_nums__types
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[description tablename
                  desc_occs occs_with_remarks occs_with_begindate
                  occs_with_enddate
                  example_rec_nums example_values]
            end
          end
        end
      end
    end
  end
end
