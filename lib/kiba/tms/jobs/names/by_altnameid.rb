# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module ByAltnameid
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_alt_names,
                destination: :names__by_altnameid,
                lookup: :names__by_constituentid
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[altnameid constituentid]
              transform Merge::MultiRowLookup,
                lookup: names__by_constituentid,
                keycolumn: :constituentid,
                fieldmap: {
                  person: :person,
                  org: :org,
                  prefname: :prefname,
                  nonprefname: :nonprefname,
                  cleanedprefname: :cleanedprefname
                }
              transform Delete::Fields, fields: :constituentid
            end
          end
        end
      end
    end
  end
end
