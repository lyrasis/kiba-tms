# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Terms
        module Preferred
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__terms,
                destination: :terms__preferred
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :keep,
                field: :prefterm
            end
          end
        end
      end
    end
  end
end
