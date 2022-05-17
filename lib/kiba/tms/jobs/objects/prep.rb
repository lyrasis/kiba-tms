# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__objects,
                destination: :prep__objects,
                lookup: %i[prep__classifications prep__classification_xrefs prep__departments prep__object_statuses]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::Fields,
                fields: %i[catalogueisodate conservationentityid
                           curatorapproved curatorrevisodate dateeffectiveisodate injurisdiction
                           istemplate objectnamealtid objectnameid
                           objectscreenid searchobjectnumber sortnumber sortnumber2
                           sortsearchnumber]
              transform FilterRows::FieldEqualTo, action: :reject, field: :objectid, value: '-1'

              transform Merge::MultiRowLookup,
                keycolumn: :classificationid,
                lookup: prep__classifications,
                fieldmap: {
                  classification: :classification
                },
                delim: Tms.delim
              transform Delete::Fields, fields: :classificationid

              transform Merge::MultiRowLookup,
                keycolumn: :objectid,
                lookup: prep__classification_xrefs,
                fieldmap: {
                  classificationxref: :classification
                },
                delim: Tms.delim
              
              transform Merge::MultiRowLookup,
                keycolumn: :departmentid,
                lookup: prep__departments,
                fieldmap: {
                  department: :department
                },
                delim: Tms.delim
              transform Delete::Fields, fields: :departmentid

              transform Merge::MultiRowLookup,
                keycolumn: :objectstatusid,
                lookup: prep__object_statuses,
                fieldmap: {
                  objectstatus: :objectstatus
                },
                delim: Tms.delim
              transform Delete::Fields, fields: :objectstatusid
            end
          end
        end
      end
    end
  end
end