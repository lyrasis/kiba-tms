# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Conditions
        module Nhrs
          module_function

          def job
            return unless config.used?

          Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :conditions__nhrs
              },
              transformer: xforms
            )
          end

          def sources
            %i[
               :conditions__nhr_objects
              ].select{ |job| Tms.job_output?(job) }
          end

          def xforms
            Kiba.job_segment do
              #compile-only job
            end
          end
        end
      end
    end
  end
end
