# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module Series
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__reference_master,
                destination: :reference_master__series
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: :series
              transform Deduplicate::Table,
                field: :series
              transform Rename::Field,
                from: :series,
                to: :title
              transform do |row|
                row[:referenceid] = "series - #{row[:title]}"
                row
              end
              transform Merge::ConstantValue,
                target: :termtype,
                value: "series"
            end
          end
        end
      end
    end
  end
end
