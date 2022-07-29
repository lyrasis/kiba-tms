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
            if Tms::Objects::FieldXforms.classifications
              %i[prep__classifications prep__classification_xrefs].each{ |lkup| result << lkup }
            end
            result << :text_entries__for_objects if Tms::TextEntries.target_tables.any?('Objects')
            result << :alt_nums__for_objects if Tms::AltNums.target_tables.any?('Objects')
            result << :prep__status_flags if Tms::StatusFlags.target_tables.any?('Objects')
            result
          end
          
          def xforms
            Kiba.job_segment do
              custom_handled_fields = Tms::Objects::Config.custom_map_fields
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
              transform Delete::EmptyFields, consider_blank: Tms::Objects::Config.consider_blank

              client_specific_delete_fields = Tms::Objects::Config.delete_fields
              unless client_specific_delete_fields.empty?
                transform Delete::Fields, fields: client_specific_delete_fields
              end
              
              transform FilterRows::FieldEqualTo, action: :reject, field: :objectid, value: '-1'

              if Tms::Objects::FieldXforms.classifications
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
                  Tms::Objects::Config.department_target => :department
                },
                delim: Tms.delim
              transform Delete::Fields, fields: :departmentid

              if Tms::Objects::Config.department_coll_prefix
                transform Prepend::ToFieldValue,
                  field: Tms::Objects::Config.department_target,
                  value: Tms::Objects::Config.department_coll_prefix
              end
              
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
                    .select{ |row| Tms::ConXrefDetails.for_objects.production_con_roles.any?(row[:role]) }
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
                    .select{ |row| Tms::ConXrefDetails.for_objects.production_con_roles.any?(row[:role]) }
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
                    .select{ |row| Tms::ConXrefDetails.for_objects.assoc_con_roles.any?(row[:role]) }
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
                    .select{ |row| Tms::ConXrefDetails.for_objects.assoc_con_roles.any?(row[:role]) }
                    .map{ |row| ["#{row[:person]} #{row[:role]}", row] }
                    .to_h
                    .values
                end,
                sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i),
                delim: Tms.delim,
                null_placeholder: '%NULLVALUE%'

              if Tms::AltNums.target_tables.any?('Objects')
                transform Merge::MultiRowLookup,
                  keycolumn: :objectid,
                  lookup: alt_nums__for_objects,
                  fieldmap: {
                    numbervalue: :altnum,
                    numbertype: :description
                  },
                  sorter: Lookup::RowSorter.new(on: :sort, as: :to_i),
                  delim: Tms.delim,
                  null_placeholder: '%NULLVALUE%'
                transform Merge::MultiRowLookup,
                  keycolumn: :objectid,
                  lookup: alt_nums__for_objects,
                  fieldmap: {alt_num_comment: :remarks},
                  sorter: Lookup::RowSorter.new(on: :sort, as: :to_i),
                  delim: Tms.delim
                transform Prepend::ToFieldValue, field: :alt_num_comment, value: 'Other number note: '
              end

              if Tms::StatusFlags.target_tables.any?('Objects')
                transform Merge::MultiRowLookup,
                  keycolumn: :objectid,
                  lookup: prep__status_flags,
                  fieldmap: {status_flag_inventorystatus: :flaglabel},
                  sorter: Lookup::RowSorter.new(on: :sort, as: :to_i),
                  delim: Tms.delim,
                  conditions: ->(_origrow, mergerows){ mergerows.select{ |row| row[:tablename] == 'Objects' } }
                transform Tms::Transforms::Objects::CombineObjectStatusAndStatusFlags
              end
              
              if Tms::Objects::FieldXforms.text_entries
                Tms::Objects::Config.config.text_entry_lookup = text_entries__for_objects
                transform Tms::Objects::FieldXforms.text_entries
              end


              %i[culture inscribed markings medium signed].each do |source|
                xform = Tms::Objects::Cleaners.send(source)
                if xform
                  transform do |row|
                    xform.process(row)
                  end
                end
              end
              %i[creditline curatorialremarks inscribed markings signed].each do |source|
                xform = Tms::Objects::FieldXforms.send(source)
                if xform
                  transform do |row|
                    xform.process(row)
                  end
                end
              end
              
              rename_map = {
                chat: :viewerscontributionnote,
                culture: :objectproductionpeople,
                description: :briefdescription,
                dimensions: :dimensionsummary,
                medium: :materialtechniquedescription,
                notes: :comment,
                objectcount: :numberofobjects,
              }
              custom_handled_fields.each{ |field| rename_map.delete(field) }
              transform Rename::Fields, fieldmap: rename_map.merge(Tms::Objects::Config.custom_rename_fieldmap)

              %w[annotation nontext_inscription text_inscription].each do |type|
                sources = Tms::Objects::Config.send("#{type}_source_fields".to_sym)
                targets = Tms::Objects::Config.send("#{type}_target_fields".to_sym)
                if !sources.empty? && !targets.empty?
                  transform Collapse::FieldsToRepeatableFieldGroup,
                    sources: sources,
                    targets: targets,
                    delim: Tms.delim
                end
              end

              if Tms::AltNums.target_tables.any?('Objects')
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: %i[comment alt_num_comment],
                  target: :comment,
                  sep: Tms.delim,
                  delete_sources: true
              end

              unless Tms::Objects::Config.named_coll_fields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: Tms::Objects::Config.named_coll_fields,
                  target: :namedcollection,
                  sep: Tms.delim,
                  delete_sources: true
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
