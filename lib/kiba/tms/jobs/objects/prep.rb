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
            if Tms::Objects.classifications_xform
              %i[prep__classifications prep__classification_xrefs].each do |lkup|
                base << lkup
              end
            end
            if Tms::TextEntries.for?('Objects')
              base << :text_entries_for__objects
            end
            base << :alt_nums_for__objects if Tms::AltNums.for?('Objects')
            base << :prep__status_flags if Tms::StatusFlags.for?('Objects')
            base << :prep__object_names if Tms::ObjectNames.used?
            base << :prep__obj_titles if Tms::ObjTitles.used?
            if Tms::DimItemElemXrefs.for?('Objects')
              base << :dim_item_elem_xrefs_for__objects
            end
            if Tms::ObjComponents.merging_text_entries?
              base << :obj_components__with_object_numbers
            end
            if Tms::LinkedSetAcq.used?
              base << :linked_set_acq__object_statuses
            end
            base
          end

          def field_cleaners
            %i[culture inscribed markings medium signed].map do |field|
              "#{field}_cleaner".to_sym
            end.select{ |setting| config.respond_to?(setting) }
              .map{ |setting| config.send(setting) }
              .compact
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

              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :objectid,
                value: '-1'

              if Tms::Departments.used?
                transform Merge::MultiRowLookup,
                  keycolumn: :departmentid,
                  lookup: prep__departments,
                  fieldmap: {
                    config.department_target => :department
                  },
                  delim: Tms.delim
              end
              transform Delete::Fields, fields: :departmentid

              if config.department_coll_prefix
                transform Prepend::ToFieldValue,
                  field: config.department_target,
                  value: config.department_coll_prefix
              end

              if Tms::ObjectNames.used?
                transform Rename::Field,
                  from: :objectname,
                  to: :obj_objectname
                transform Append::NilFields,
                  fields: %i[obj_objectnametype obj_objectnamelanguage
                             obj_objectnamenote]
                transform Merge::MultiRowLookup,
                  lookup: prep__object_names,
                  keycolumn: :objectid,
                  fieldmap: {
                    on_objectname: :objectname,
                    on_objectnametype: :objectnametype,
                    on_objectnamelanguage: :language,
                    on_objectnamenote: :remarks
                  },
                  sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i)
                transform Tms::Transforms::ClearContainedFields,
                  a: :obj_objectname,
                  b: :on_objectname,
                  delim: Tms.delim
              end

              statusfields = []
              if Tms::ObjectStatuses.used?
                transform Merge::MultiRowLookup,
                  keycolumn: :objectstatusid,
                  lookup: prep__object_statuses,
                  fieldmap: {
                    main_objectstatus: :objectstatus
                  },
                  delim: Tms.delim
                statusfields << :main_objectstatus
              end
              transform Delete::Fields, fields: :objectstatusid

              if Tms::LinkedSetAcq.used?
                transform Merge::MultiRowLookup,
                  lookup: linked_set_acq__object_statuses,
                  keycolumn: :objectid,
                  fieldmap: {
                    linkedset_objectstatus: :objectstatus
                  },
                  delim: Tms.delim
                statusfields << :linkedset_objectstatus
              end

              unless statusfields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: statusfields,
                  target: :objectstatus,
                  sep: Tms.delim,
                  delete_sources: true
                transform Deduplicate::FieldValues,
                  fields: :objectstatus,
                  sep: Tms.delim
              end

              if Tms::ObjTitles.used?
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

                # if no title merged in from ObjTitles, move :title
                #   to :obj_title
                transform do |row|
                  ot = row[:obj_title]
                  next row unless ot.blank?

                  row[:obj_title] = row[:title]
                  row
                end

                transform Delete::Fields, fields: :title
                transform Rename::Field, from: :obj_title, to: :title
              end

              if Tms::ObjContext.used?
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
              end

              if Tms::DimItemElemXrefs.used?
                transform Merge::MultiRowLookup,
                  lookup: dim_item_elem_xrefs_for__objects,
                  keycolumn: :objectid,
                  fieldmap: {
                    diex_dims: :displaydimensions,
                    diex_date: :dimensiondate,
                    diex_desc: :description,
                    diex_elem: :element
                  },
                  sorter: Lookup::RowSorter.new(on: :rank, as: :to_i)
              end

              if Tms::ConRefs.for?('Objects')
                transform Tms::Transforms::ConRefs::Merger,
                  into: config,
                  keycolumn: :objectid
              end

              if Tms::AltNums.for?('Objects')
                transform Merge::MultiRowLookup,
                  keycolumn: :objectid,
                  lookup: alt_nums_for__objects,
                  fieldmap: {
                    numbervalue: :altnum,
                    numbertype: :description
                  },
                  sorter: Lookup::RowSorter.new(on: :sort, as: :to_i),
                  delim: Tms.delim,
                  null_placeholder: '%NULLVALUE%'
                transform Merge::MultiRowLookup,
                  keycolumn: :objectid,
                  lookup: alt_nums_for__objects,
                  fieldmap: {alt_num_comment: :remarks},
                  sorter: Lookup::RowSorter.new(on: :sort, as: :to_i),
                  delim: Tms.delim
                transform Prepend::ToFieldValue,
                  field: :alt_num_comment,
                  value: 'Other number note: '
              end

              if Tms::StatusFlags.for?('Objects')
                transform Merge::MultiRowLookup,
                  keycolumn: :objectid,
                  lookup: prep__status_flags,
                  fieldmap: {status_flag_inventorystatus: :flaglabel},
                  sorter: Lookup::RowSorter.new(on: :sort, as: :to_i),
                  delim: Tms.delim,
                  conditions: ->(_origrow, mergerows){
                    mergerows.select{ |row| row[:tablename] == 'Objects' }
                  }
                transform Tms::Transforms::Objects::CombineObjectStatusAndStatusFlags
              end

              if Tms::ObjComponents.merging_text_entries?
                transform Merge::MultiRowLookup,
                  keycolumn: :objectid,
                  lookup: obj_components__with_object_numbers,
                  fieldmap: {tecomp_comment: :te_comment},
                  delim: Tms.delim
              end

              if config.text_entries_merge_xform
                xform = config.text_entries_merge_xform.new(
                  text_entries_for__objects
                )
                transform{ |row| xform.process(row) }
              end

              bind.receiver.send(:field_cleaners).each do |cleaner|
                  transform do |row|
                    cleaner.process(row)
                  end
                end

              config.transformer_fields.each do |field|
                setting = "#{field}_xform".to_sym
                xform = config.send(setting)
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
              transform Rename::Fields,
                fieldmap: rename_map.merge(Tms::Objects.custom_rename_fieldmap)

              %w[annotation nontext_inscription text_inscription].each do |type|
                sources = Tms::Objects.send("#{type}_source_fields".to_sym)
                targets = Tms::Objects.send("#{type}_target_fields".to_sym)
                if !sources.empty? && !targets.empty?
                  transform Collapse::FieldsToRepeatableFieldGroup,
                    sources: sources,
                    targets: targets,
                    delim: Tms.delim
                end
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: Tms::Objects.comment_fields,
                target: :comment,
                sep: Tms.delim,
                delete_sources: true


              unless Tms::Objects.named_coll_fields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: Tms::Objects.named_coll_fields,
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
