# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConXrefs
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_xrefs,
                destination: :prep__con_xrefs,
                lookup: :prep__roles
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::TmsTableNames
              transform Delete::Fields, fields: %i[displayed active isdefaultdisplaybio roletypeid]
              transform Rename::Field, from: :id, to: :recordid
              transform Merge::MultiRowLookup,
                lookup: prep__roles,
                keycolumn: :roleid,
                fieldmap: {
                  role: :role,
                  roletype: :roletype
                }
              transform Delete::Fields, fields: :roleid
            end
          end
        end
      end
    end
  end
end
