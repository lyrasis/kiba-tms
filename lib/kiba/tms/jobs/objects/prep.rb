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
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            result = %i[
                        prep__departments
                        prep__object_statuses
                        prep__obj_context
                        con_xref_details__for_objects
                       ]
            if Tms.objects.source_xform.classifications
              %i[prep__classifications prep__classification_xrefs].each{ |lkup| result << lkup }
            end
            result << :text_entries__for_objects if Tms.objects.source_xform.text_entries
            result
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

              if Tms.objects.source_xform.classifications
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
              end
              
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

              transform Merge::MultiRowLookup,
                keycolumn: :objectid,
                lookup: con_xref_details__for_objects,
                fieldmap: {
                  objectproductionperson: :person,
                  objectproductionpersonrole: :role
                },
                conditions: ->(_origrow, mergerows) do
                  mergerows.reject{ |row| row[:person].blank? }
                    .select{ |row| Tms.objects.production_roles.any?(row[:role]) }
                    .map{ |row| ["#{row[:person]} #{row[:role]}", row] }
                    .to_h
                    .values
                end,
                sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i),
                delim: Tms.delim,
                null_placeholder: '%NULLVALUE%'

              transform Merge::MultiRowLookup,
                keycolumn: :objectid,
                lookup: con_xref_details__for_objects,
                fieldmap: {
                  objectproductionorganization: :org,
                  objectproductionorganizationrole: :role
                },
                conditions: ->(_origrow, mergerows) do
                  mergerows.reject{ |row| row[:org].blank? }
                    .select{ |row| Tms.objects.production_roles.any?(row[:role]) }
                    .map{ |row| ["#{row[:org]} #{row[:role]}", row] }
                    .to_h
                    .values
                end,
                sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i),
                delim: Tms.delim,
                null_placeholder: '%NULLVALUE%'

              transform Merge::MultiRowLookup,
                keycolumn: :objectid,
                lookup: con_xref_details__for_objects,
                fieldmap: {
                  assocperson: :person,
                  assocpersontype: :role,
                  assocpersonnote: :assoc_con_note
                },
                conditions: ->(_origrow, mergerows) do
                  mergerows.reject{ |row| row[:person].blank? }
                    .select{ |row| Tms.objects.assoc_roles.any?(row[:role]) }
                    .map{ |row| ["#{row[:person]} #{row[:role]}", row] }
                    .to_h
                    .values
                end,
                sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i),
                delim: Tms.delim,
                null_placeholder: '%NULLVALUE%'
              transform Merge::MultiRowLookup,
                keycolumn: :objectid,
                lookup: con_xref_details__for_objects,
                fieldmap: {
                  assocorganization: :org,
                  assocorganizationtype: :role,
                  assocorganizationnote: :assoc_con_note
                },
                conditions: ->(_origrow, mergerows) do
                  mergerows.reject{ |row| row[:org].blank? }
                    .select{ |row| Tms.objects.assoc_roles.any?(row[:role]) }
                    .map{ |row| ["#{row[:person]} #{row[:role]}", row] }
                    .to_h
                    .values
                end,
                sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i),
                delim: Tms.delim,
                null_placeholder: '%NULLVALUE%'

              if Tms.objects.source_xform.text_entries
                Tms.objects.source_xform.text_entry_lookup = text_entries__for_objects
                transform Tms.objects.source_xform.text_entries
              end


              %i[inscribed signed markings].each do |source|
                xform = Tms.objects.cleaner.send(source)
                if xform
                  transform do |row|
                    xform.process(row)
                  end
                end
              end
              %i[creditline curatorialremarks inscribed markings signed].each do |source|
                xform = Tms.objects.source_xform.send(source)
                if xform
                  transform do |row|
                    xform.process(row)
                  end
                end
              end
              
              rename_map = {
                chat: :viewerscontributionnote,
                description: :briefdescription,
                medium: :materialtechniquedescription,
                notes: :comment,
                objectcount: :numberofobjects,
                dimensions: :dimensionsummary
              }
              custom_handled_fields.each{ |field| rename_map.delete(field) }
              transform Rename::Fields, fieldmap: rename_map.merge(Tms.objects.custom_rename_fieldmap)

              %w[annotation nontext_inscription text_inscription].each do |type|
                sources = Tms.objects.send("#{type}_source_fields".to_sym)
                targets = Tms.objects.send("#{type}_target_fields".to_sym)
                if !sources.empty? && !targets.empty?
                  transform Kiba::Extend::Transforms::Cspace::FieldGroupCombiner,
                    sources: sources,
                    targets: targets
                end
              end
              
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
