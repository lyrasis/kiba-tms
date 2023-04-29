# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConservationTreatments
        module All
          module_function

          def job
            return if sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :conservation_treatments__all
              },
              transformer: xforms
            )
          end

          def sources
            base = %i[
              conservation_treatments__from_cond_line_items
            ]
            base.select { |key| Tms.job_output?(key) }
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::IdGenerator,
                prefix: "CT",
                id_source: :recordnumber,
                id_target: :conservationnumber,
                delete_source: false,
                omit_suffix_if_single: false
              transform Delete::EmptyFields
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
