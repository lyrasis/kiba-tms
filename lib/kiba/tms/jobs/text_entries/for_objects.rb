# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TextEntries
        module ForObjects
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__text_entries,
                destination: :text_entries__for_objects
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :table, value: 'Objects'
            end
          end
        end
      end
    end
  end
end
