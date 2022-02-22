# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        extend self

        def prep
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__objects,
              destination: :prep__objects,
              lookup: %i[prep__classifications prep__classification_xrefs prep__departments prep__object_statuses]
            },
            transformer: prep_xforms
          )
        end

        def prep_xforms
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
        
        def object_number_lookup
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__objects,
              destination: :prep__object_number_lookup
            },
            transformer: object_number_lookup_xforms
          )
        end

        def object_number_lookup_xforms
          Kiba.job_segment do
            transform Delete::FieldsExcept, keepfields: %i[objectid objectnumber]
          end
        end

        def object_numbers
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__objects,
              destination: :prep__object_numbers
            },
            transformer: object_numbers_xforms
          )
        end

        def object_numbers_xforms
          Kiba.job_segment do
            transform Delete::FieldsExcept, keepfields: %i[objectnumber]
          end
        end
      end
    end
  end
end
