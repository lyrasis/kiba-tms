# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TextEntries
        module ForConstituents
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__text_entries,
                destination: :text_entries__for_constituents
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :table, value: 'Constituents'
              transform Tms::Transforms::TextEntries::ForConstituents
            end
          end
        end
      end
    end
  end
end
