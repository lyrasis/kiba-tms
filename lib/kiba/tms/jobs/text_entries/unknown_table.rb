# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TextEntries
        module UnknownTable
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__text_entries,
                destination: :text_entries__unknown_table,
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :reject, field: :table
            end
          end
        end
      end
    end
  end
end
