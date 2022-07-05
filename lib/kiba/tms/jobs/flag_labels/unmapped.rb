# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module FlagLabels
        module Unmapped
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__flag_labels,
                destination: :flag_labels__unmapped
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :flaglabel, value: 'NEEDS MAPPING'
           end
          end
        end
      end
    end
  end
end
