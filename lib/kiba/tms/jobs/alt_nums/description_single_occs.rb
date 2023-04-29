# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module DescriptionSingleOccs
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :alt_nums__description_occs,
                destination: :alt_nums__description_single_occs
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :desc_occs,
                value: "1"
            end
          end
        end
      end
    end
  end
end
