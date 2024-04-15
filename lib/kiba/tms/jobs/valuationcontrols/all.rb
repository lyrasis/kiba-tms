# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Valuationcontrols
        module All
          module_function

          def job
            return if sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :valuationcontrols__all
              },
              transformer: xforms
            )
          end

          def sources
            config.source_jobs
              .select { |job| Tms.job_output?(job) }
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::IdGenerator,
                prefix: "VC",
                id_source: :idbase,
                id_target: :valuationcontrolrefnumber,
                omit_suffix_if_single: false,
                sort_on: :valuedate
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
