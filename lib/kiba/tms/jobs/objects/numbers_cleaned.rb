# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        module NumbersCleaned
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__objects,
                destination: :objects__numbers_cleaned
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              if config.number_cleaner
                transform config.number_cleaner
              end
            end
          end
        end
      end
    end
  end
end
