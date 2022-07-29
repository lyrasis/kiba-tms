# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module Persons
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__with_name_data,
                destination: :constituents__persons
              },
              transformer: xforms
            )
          end
          
          def xforms
            Kiba.job_segment do
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row){ row[:constituenttype] == 'Person' || row[:derivedcontype] == 'Person' }
            end
          end
        end
      end
    end
  end
end
