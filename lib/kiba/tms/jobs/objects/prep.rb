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
                           text_entries__for_objects
                          ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              custom_handled_fields = Tms.objects.custom_map_fields
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
                keycolumn: :objectid,
                lookup: prep__classification_xrefs,
                fieldmap: {xrefclassid: :classificationid},
                delim: Tms.delim

              transform do |row|
                row[:cids] = nil
                cid = row[:classificationid]
                xcid = row[:xrefclassid]
                if xcid.blank?
                  row[:cids] = cid
                  next row
                end
                
                added = xcid.split(Tms.delim)
                  .reject{ |val| val == cid }
                  .join(Tms.delim)
                row[:cids] = [cid, added].reject{ |val| val.blank? }
                  .join(Tms.delim)
                row
              end
              transform Delete::Fields, fields: %i[classificationid xrefclassid]
              
              transform Merge::MultiRowLookup,
                keycolumn: :cids,
                lookup: prep__classifications,
                fieldmap: Tms.classifications.fieldmap,
                delim: Tms.delim,
                null_placeholder: '%NULLVALUE%',
                multikey: true
              transform Delete::Fields, fields: :cids

              # cxrefmap = Tms.classifications.fieldmap
              # cxrefmap.transform_keys!{ |key| "xref_#{key}" }
              
              # sorter = Lookup::RowSorter.new(on: :sort, as: :to_i)
              # transform Merge::MultiRowLookup,
              #   keycolumn: :objectid,
              #   lookup: prep__classification_xrefs,
              #   fieldmap: cxrefmap,
              #   delim: Tms.delim,
              #   sorter: sorter
              
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

              te_sorter = Lookup::RowSorter.new(on: :sort, as: :to_i)
              transform Merge::MultiRowLookup,
                lookup: text_entries__for_objects,
                keycolumn: :objectid,
                fieldmap: {
                  text_entry: :text_entry
                },
                delim: '%CR%%CR%----%CR%%CR%',
                sorter: te_sorter

              transform Tms.objects.source_xform.inscribed if Tms.objects.source_xform.inscribed
              transform Tms.objects.source_xform.signed if Tms.objects.source_xform.signed
              transform Tms.objects.source_xform.markings if Tms.objects.source_xform.markings
              tisources = Tms.objects.text_inscription_source_fields
              titargets = Tms.objects.text_inscription_target_fields
              if !tisources.empty? && !titargets.empty?
                transform Tms::Transforms::Objects::TextInscriptionCombiner
              end
              
              rename_map = {
                chat: :viewerscontributionnote,
                description: :briefdescription,
                medium: :materialtechniquedescription,
                notes: :comment
              }
              custom_handled_fields.each{ |field| rename_map.delete(field) }
              transform Rename::Fields, fieldmap: rename_map.merge(Tms.objects.custom_rename_fieldmap)

              
              if Tms.data_cleaner
                transform Tms.data_cleaner
              end
            end
          end
        end
      end
    end
  end
end
