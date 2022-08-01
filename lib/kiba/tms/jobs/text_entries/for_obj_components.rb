# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TextEntries
        module ForObjComponents
          module_function

          def job
            return unless Tms::TextEntries.target_tables.any?('ObjComponents')
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__text_entries,
                destination: :text_entries__for_obj_components
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :tablename, value: 'ObjComponents'
              transform Delete::Fields, fields: %i[tableid table]

              if Tms::TextEntries.for_obj_components_transform
                transform Tms::TextEntries.for_obj_components_transform
              end
            end
          end
        end
      end
    end
  end
end
