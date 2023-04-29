# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module PreviousWorksheetCompile
          module_function

          def job
            return unless config.done
            return if config.provided_worksheets.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.provided_worksheet_jobs,
                destination: :name_compile__previous_worksheet_compile
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              idcreator = CombineValues::FromFieldsWithDelimiter.new(
                sources: %i[authority name constituentid relation_type
                  termsource],
                target: :cleanupid,
                sep: " ",
                delete_sources: false
              )
              transform do |row|
                id = row[:cleanupid]
                next row unless id.blank?

                idcreator.process(row)
                row
              end
              transform Deduplicate::Table,
                field: :cleanupid,
                delete_field: false
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
