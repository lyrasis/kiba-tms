# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Citations
        module Preload
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :citations__preload
              },
              transformer: xforms
            )
          end

          def sources
            %i[
              reference_master__journal_lookup
              reference_master__series_lookup
            ].select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :reject,
                field: :drop
              transform Delete::Fields,
                fields: %i[referenceid drop]
              transform Rename::Fields, fieldmap: {
                heading: :termdisplayname,
                title: :termtitle
              }
              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
