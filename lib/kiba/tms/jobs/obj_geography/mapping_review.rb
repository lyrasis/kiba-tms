# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjGeography
        module MappingReview
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_geography,
                destination: :obj_geography__mapping_review,
                lookup: :tms__objects
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: tms__objects,
                keycolumn: :objectid,
                fieldmap: {
                  objectnumber: :objectnumber,
                  objecttitle: :title,
                  objectdesc: :description
                }

              transform Tms.final_data_cleaner if Tms.final_data_cleaner
              transform Sort::ByFieldValue,
                field: :objectnumber,
                mode: :string
            end
          end
        end
      end
    end
  end
end
