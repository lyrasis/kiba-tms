# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TextEntries
        module ForObjects
          module_function

          def job
            return unless Tms::TextEntries.for?('Objects')
            
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
              transform FilterRows::FieldEqualTo, action: :keep, field: :tablename, value: 'Objects'
              transform Delete::Fields, fields: %i[tableid table]
              
              if Tms::TextEntries.for_objects_transform
                transform Tms::TextEntries.for_objects_transform
              end
            end
          end
        end
      end
    end
  end
end
