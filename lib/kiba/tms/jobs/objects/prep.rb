# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        module Prep
          module_function

          def job
            return unless config.used?
            
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
            base = []
            base << :prep__departments if Tms::Departments.used?
            base << :prep__object_statuses if Tms::ObjectStatuses.used?
            base << :prep__obj_context if Tms::ObjContext.used?
            base << :con_xref_details__for_objects if Tms::ConXrefDetails.for?('Objects')
            if Tms::Objects::FieldXforms.classifications
              %i[prep__classifications prep__classification_xrefs].each{ |lkup| base << lkup }
            end
            base << :text_entries__for_objects if Tms::TextEntries.for?('Objects')
            base << :alt_nums__for_objects if Tms::AltNums.for?('Objects')
            base << :prep__status_flags if Tms::StatusFlags.for?('Objects')
            base << :prep__obj_titles if Tms::ObjTitles.used?
            base << :obj_components__with_object_numbers if Tms::ObjComponents.merging_text_entries?
            base
          end
          
          def xforms
            bind = binding
            
            Kiba.job_segment do
              config = bind.receiver.send(:config)
              custom_handled_fields = config.custom_map_fields

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform FilterRows::FieldEqualTo, action: :reject, field: :objectid, value: '-1'

              if config.classifications_xform
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

              if Tms::Table::List.include?('ObjTitles')
                transform Merge::MultiRowLookup,
                  lookup: prep__obj_titles,
                  keycolumn: :objectid,
                  fieldmap: {
                    obj_title: :title,
                    titletype: :titletype,
                    titlelanguage: :language,
                    title_comment: :titlenote
                  },
                  delim: Tms.delim,
                  sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i)
                
                # if no title merged in from ObjTitles, move :title to :obj_title
                transform do |row|
                  ot = row[:obj_title]
                  next row unless ot.blank?

                  row[:obj_title] = row[:title]
                  row
                end

                transform Delete::Fields, fields: :title
                transform Rename::Field, from: :obj_title, to: :title
              end

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

              if Tms::AltNums.for?('Objects')
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

              if Tms::StatusFlags.for?('Objects')
                transform Merge::MultiRowLookup,
                  keycolumn: :objectid,
                  lookup: prep__status_flags,
                  fieldmap: {status_flag_inventorystatus: :flaglabel},
                  sorter: Lookup::RowSorter.new(on: :sort, as: :to_i),
                  delim: Tms.delim,
                  conditions: ->(_origrow, mergerows){ mergerows.select{ |row| row[:tablename] == 'Objects' } }
                transform Tms::Transforms::Objects::CombineObjectStatusAndStatusFlags
              end

              if Tms::ObjComponents.merging_text_entries?
                transform Merge::MultiRowLookup,
                  keycolumn: :objectid,
                  lookup: obj_components__with_object_numbers,
                  fieldmap: {tecomp_comment: :te_comment},
                  delim: Tms.delim
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
              
              transform CombineValues::FromFieldsWithDelimiter,
                sources: Tms::Objects::Config.comment_fields,
                target: :comment,
                sep: Tms.delim,
                delete_sources: true


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
