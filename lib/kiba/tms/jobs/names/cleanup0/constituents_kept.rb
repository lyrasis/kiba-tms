# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module Cleanup0
          module ConstituentsKept
            module_function

            def job
              Kiba::Extend::Jobs::Job.new(
                files: {
                  source: :nameclean0__kept,
                  destination: :nameclean0__constituents_kept
                },
                transformer: xforms
              )
            end

            def xforms
              Kiba.job_segment do
                transform FilterRows::FieldPopulated, action: :keep,
                  field: :fp_constituentid
              end
            end
          end
        end
      end
    end
  end
end
