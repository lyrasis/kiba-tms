# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module Compile
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :places__compile
              },
              transformer: xforms
            )
          end

          def sources
            config.compile_sources
              .select{ |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            Kiba.job_segment do
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
