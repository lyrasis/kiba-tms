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
                lookup: %i[
                           prep__classifications
                           prep__classification_xrefs
                           prep__departments
                           prep__object_statuses
                           prep__obj_context
                          ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              unless Tms.conservationentity_used
                transform Delete::Fields, fields: :conservationentityid
              end

              # tms internal and data model omissionfields
              transform Delete::Fields,
                fields: %i[curatorapproved injurisdiction istemplate isvirtual
                           curatorrevisodate
                           searchobjectnumber sortnumber sortnumber2 sortsearchnumber usernumber3
                           objectscreenid textsearchid]
              transform Delete::EmptyFields, consider_blank: {
                loanclassid: '0',
                objectlevelid: '0',
                objecttypeid: '0',
                publicaccess: '0',
                subclassid: '0',
                type: '0',
              }

              client_specific_delete_fields = Tms.objects.delete_fields
              unless client_specific_delete_fields.empty?
                transform Delete::Fields, fields: client_specific_delete_fields
              end
              
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

              transform Merge::MultiRowLookup,
                keycolumn: :objectid,
                lookup: prep__obj_context,
                fieldmap: {
                  culture: :culture
                },
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                keycolumn: :objectid,
                lookup: prep__obj_context,
                fieldmap: {
                  period: :period
                },
                delim: Tms.delim


              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: '^(%CR%)+',
                replace: ''
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: '(%CR%)+$',
                replace: ''
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: '(%CR%){3,}',
                replace: '%CR%%CR%'
            end
          end
        end
      end
    end
  end
end
