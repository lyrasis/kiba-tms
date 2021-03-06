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
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[
                      prep__con_xrefs
                     ]

            if Tms.names.cleanup_iteration
              base << :persons__by_constituentid
              base << :orgs__by_constituentid
            else
              base << :constituents__persons
              base << :constituents__orgs
            end
            base
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              # :nameid links to ConAltNames table. We don't deal with alt names at the point of merging
              #   authorized forms of names into records
              transform Delete::Fields, fields: %i[conxrefdetailid roletypeid addressid nameid]

              if Tms.names.cleanup_iteration
                transform Merge::MultiRowLookup,
                  lookup: persons__by_constituentid,
                  keycolumn: :constituentid,
                  fieldmap: {person: Tms::Constituents.preferred_name_field}
                transform Merge::MultiRowLookup,
                  lookup: orgs__by_constituentid,
                  keycolumn: :constituentid,
                  fieldmap: {org: Tms::Constituents.preferred_name_field}
              else
                transform Merge::MultiRowLookup,
                  lookup: constituents__persons,
                  keycolumn: :constituentid,
                  fieldmap: {person: Tms::Constituents.preferred_name_field}
                transform Merge::MultiRowLookup,
                  lookup: constituents__orgs,
                  keycolumn: :constituentid,
                  fieldmap: {org: Tms::Constituents.preferred_name_field}
              end
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

              transform Clean::RegexpFindReplaceFieldVals,
                fields: %i[datebegin dateend amount],
                find: '^0$',
                replace: ''
            end
          end
        end
      end
    end
  end
end
