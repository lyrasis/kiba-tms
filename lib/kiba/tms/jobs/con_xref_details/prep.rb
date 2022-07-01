# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConXrefDetails
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_xref_details,
                destination: :prep__con_xref_details,
                lookup: %i[
                           persons__by_constituentid
                           orgs__by_constituentid
                           prep__con_xrefs
                          ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::Fields, fields: %i[conxrefdetailid roletypeid addressid]
              transform Merge::MultiRowLookup,
                lookup: persons__by_constituentid,
                keycolumn: :constituentid,
                fieldmap: {person: Tms.constituents.preferred_name_field}
              transform Merge::MultiRowLookup,
                lookup: orgs__by_constituentid,
                keycolumn: :constituentid,
                fieldmap: {org: Tms.constituents.preferred_name_field}
              transform Delete::Fields, fields: :constituentid

              transform Merge::MultiRowLookup,
                lookup: prep__con_xrefs,
                keycolumn: :conxrefid,
                fieldmap: {
                  role: :role,
                  roletype: :roletype,
                  displayorder: :displayorder,
                  tablename: :tablename,
                  recordid: :recordid
                }
              transform Delete::Fields, fields: :conxrefid
            end
          end
        end
      end
    end
  end
end
