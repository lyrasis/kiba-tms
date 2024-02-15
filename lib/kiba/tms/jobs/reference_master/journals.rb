# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module Journals
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__reference_master,
                destination: :reference_master__journals
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: :journal
              transform Deduplicate::Table,
                field: :journal
              transform Rename::Field,
                from: :journal,
                to: :title
              transform do |row|
                row[:referenceid] = "journal - #{row[:title]}"
                row
              end
              transform Merge::ConstantValue,
                target: :termtype,
                value: "journal"
            end
          end
        end
      end
    end
  end
end
