# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConservationTreatments
        module NhrsAll
          module_function

          def job
            return if sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :conservation_treatments__nhrs_all
              },
              transformer: xforms
            )
          end

          def sources
            base = %i[
              conservation_treatments__nhrs_cond_line_items
            ]
            base.select { |key| Tms.job_output?(key) }
          end

          def xforms
            Kiba.job_segment do
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[item1_id item1_type item2_id item2_type],
                target: :combined,
                delim: " ",
                delete_sources: false

              transform Deduplicate::Table,
                field: :combined,
                delete_field: true
            end
          end
        end
      end
    end
  end
end
