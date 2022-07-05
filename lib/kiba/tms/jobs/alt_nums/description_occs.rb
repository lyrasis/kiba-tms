# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module DescriptionOccs
          module_function

          def job
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :prep__alt_nums,
              destination: :alt_nums__description_occs,
              lookup: :prep__alt_nums
            },
            transformer: xforms
          )
          end

          def xforms
            Kiba.job_segment do
            transform FilterRows::FieldPopulated, action: :keep, field: :description
            transform Count::MatchingRowsInLookup,
              lookup: prep__alt_nums,
              keycolumn: :description,
              targetfield: :desc_occs
            end
          end
        end
      end
    end
  end
end
