# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module ByConstituentid
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__prep_clean,
                destination: :names__by_constituentid,
                lookup: %i[
                  orgs__by_constituentid
                  persons__by_constituentid
                ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              prefname = Tms::Constituents.preferred_name_field
              nonprefname = Tms::Constituents.var_name_field

              transform Delete::FieldsExcept,
                fields: [:constituentid, prefname, nonprefname]
              transform Rename::Fields, fieldmap: {
                prefname => :cleanedprefname,
                nonprefname => :nonprefname
              }

              transform Merge::MultiRowLookup,
                lookup: orgs__by_constituentid,
                keycolumn: :constituentid,
                fieldmap: {org: :name}
              transform Merge::MultiRowLookup,
                lookup: persons__by_constituentid,
                keycolumn: :constituentid,
                fieldmap: {person: :name}
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[org person],
                target: :prefname,
                sep: " ",
                delete_sources: false
            end
          end
        end
      end
    end
  end
end
