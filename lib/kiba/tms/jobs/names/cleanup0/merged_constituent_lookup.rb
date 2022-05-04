# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module Cleanup0
          module MergedConstituentLookup
            module_function

            def job
              Kiba::Extend::Jobs::Job.new(
                files: {
                  source: :names__cleaned_zero,
                  destination: :nameclean0__prep
                },
                transformer: xforms
              )
            end

            def xforms
              Kiba.job_segment do
                
              end
            end
          end
        end
      end
    end
  end
end
