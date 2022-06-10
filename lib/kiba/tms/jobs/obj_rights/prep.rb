# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjRights
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_rights,
                destination: :prep__obj_rights,
                lookup: :prep__obj_rights_types
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::EmptyFields
              transform Delete::Fields, fields: %i[objrightsid]

              transform Merge::MultiRowLookup,
                lookup: prep__obj_rights_types,
                keycolumn: :objrightstypeid,
                fieldmap: {objrightstype: :objrightstype}
              transform Delete::Fields, fields: :objrightstypeid
            end
          end
        end
      end
    end
  end
end
