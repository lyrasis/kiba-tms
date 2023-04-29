# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjIncoming
        module ForInitialReview
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_incoming,
                destination: :obj_incoming__for_initial_review,
                lookup: :objects__numbers_cleaned
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: objects__numbers_cleaned,
                keycolumn: :objectid,
                fieldmap: {objectnumber: :objectnumber}
              transform CombineValues::FromFieldsWithDelimiter,
                sources: Tms::ObjIncoming.content_fields,
                target: :combined,
                sep: " ",
                delete_sources: false
              transform FilterRows::FieldPopulated, action: :keep, field: :combined
              transform Delete::Fields, fields: :combined
              transform Delete::EmptyFields
            end
          end
        end
      end
    end
  end
end
