# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConDates
        module Compiled
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :con_dates__compiled
              },
              transformer: xforms
            )
          end

          def sources
            base = [:constituents__clean_dates]
            base << :prep__con_dates if Tms::Table::List.include?("ConDates")
            base
          end

          def xforms
            Kiba.job_segment do
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[constituentid datedescription date],
                target: :combined,
                delim: " ",
                delete_sources: false
              transform Deduplicate::Table, field: :combined, delete_field: true

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[constituentid datedescription],
                target: :combined,
                delim: " ",
                delete_sources: false

              transform Tms::Transforms::ConDates::ReducePartialDuplicates
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
