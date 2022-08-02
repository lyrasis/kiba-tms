# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjTitles
        module NoteReview
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_titles,
                destination: :obj_titles__note_review,
                lookup: :tms__objects
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :keep, field: :titlenote
              transform Delete::FieldsExcept, fields: %i[objectid titlenote]
              transform Merge::MultiRowLookup,
                lookup: tms__objects,
                keycolumn: :objectid,
                fieldmap: {objectnumber: :objectnumber}
              transform Delete::Fields, fields: :objectid
            end
          end
        end
      end
    end
  end
end
