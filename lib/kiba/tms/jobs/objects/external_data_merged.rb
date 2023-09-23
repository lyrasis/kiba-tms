# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        module ExternalDataMerged
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__objects,
                destination: :objects__external_data_merged,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :prep__obj_context if Tms::ObjContext.used?
            if Tms::Objects.classifications_xform
              %i[prep__classifications
                prep__classification_xrefs].each do |lkup|
                base << lkup
              end
            end
            if Tms::TextEntries.for?("Objects")
              base << :text_entries_for__objects
            end
            if Tms::AltNums.for?("Objects")
              base << Tms::AltNumsForObjects.merge_lookup
            end
            base << :prep__status_flags if Tms::StatusFlags.for?("Objects")
            base << :prep__object_names if Tms::ObjectNames.used?
            base << :prep__obj_titles if Tms::ObjTitles.used?
            if config.dimensions_to_merge?
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

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              custom_handled_fields = config.custom_map_fields

              if Tms::ConRefs.for?("Objects")
                if config.con_ref_name_merge_rules
                  transform Tms::Transforms::ConRefs::Merger,
                    into: config,
                    keycolumn: :objectid
                end
                if Tms::ConRefsForObjects.merger_xforms
                  Tms::ConRefsForObjects.merger_xforms.each { |xform|
                    transform xform
                  }
                end
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

              unless Tms::Objects.status_source_fields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: Tms::Objects.status_source_fields,
                  target: :objectstatus,
                  delim: Tms.delim,
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
                transform Delete::DelimiterOnlyFieldValues,
                  fields: %i[titletype titlelanguage title_comment]

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
                contexts = Tms::ObjContext.content_fields
                contexts_merged = []

                if contexts.any?(:culture)
                  transform Merge::MultiRowLookup,
                    keycolumn: :objectid,
                    lookup: prep__obj_context,
                    fieldmap: {
                      culture: :culture
                    },
                    delim: Tms.delim
                  contexts_merged << :culture
                end

                if contexts.any?(:period)
                  transform Merge::MultiRowLookup,
                    keycolumn: :objectid,
                    lookup: prep__obj_context,
                    fieldmap: {
                      period: :period
                    },
                    delim: Tms.delim
                  contexts_merged << :period
                end

                if contexts.any?(:n_signed)
                  transform Merge::MultiRowLookup,
                    keycolumn: :objectid,
                    lookup: prep__obj_context,
                    fieldmap: {
                      nsigned_inscriptioncontent: :n_signed
                    },
                    constantmap: {
                      nsigned_inscriptioncontenttype: "signed"
                    },
                    delim: Tms.delim
                  contexts_merged << :n_signed
                  config.text_inscription_source_fields << :nsigned
                end

                contexts_todo = contexts - contexts_merged
                unless contexts_todo.empty?
                  warn("Handle merging ObjContext fields: "\
                       "#{contexts_todo.join(", ")}")
                end
              end

              if config.send(:dimensions_to_merge?)
                transform Delete::Fields, fields: :dimensions
                transform Merge::MultiRowLookup,
                  lookup: dim_item_elem_xrefs_for__objects,
                  keycolumn: :objectid,
                  fieldmap: {
                    dimensionsummary: :displaydimensions,
                    valuedate: :valuedate,
                    measuredpartnote: :description,
                    measuredpart: :element,
                    measurementunit: :measurementunit,
                    value: :value,
                    dimension: :dimension
                  },
                  sorter: Lookup::RowSorter.new(on: :rank, as: :to_i)
                transform Delete::DelimiterOnlyFieldValues,
                  fields: %i[valuedate measurementunit value dimension]
              end

              if Tms::AltNums.for?("Objects")
                transform Merge::MultiRowLookup,
                  keycolumn: :objectid,
                  lookup: alt_nums_for__objects,
                  fieldmap: {
                    numbervalue: :altnum,
                    numbertype: :description
                  },
                  sorter: Lookup::RowSorter.new(on: :sort, as: :to_i),
                  delim: Tms.delim,
                  null_placeholder: "%NULLVALUE%"
                transform Merge::MultiRowLookup,
                  keycolumn: :objectid,
                  lookup: alt_nums_for__objects,
                  fieldmap: {alt_num_comment: :remarks},
                  sorter: Lookup::RowSorter.new(on: :sort, as: :to_i),
                  delim: Tms.delim
                transform Prepend::ToFieldValue,
                  field: :alt_num_comment,
                  value: "Other number note: "
              end

              if Tms::StatusFlags.for?("Objects")
                transform Merge::MultiRowLookup,
                  keycolumn: :objectid,
                  lookup: prep__status_flags,
                  fieldmap: {status_flag_inventorystatus: :flaglabel},
                  sorter: Lookup::RowSorter.new(on: :sort, as: :to_i),
                  delim: Tms.delim,
                  conditions: ->(_origrow, mergerows) {
                    mergerows.select { |row| row[:tablename] == "Objects" }
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
                transform { |row| xform.process(row) }
              end

              unless config.transformer_fields.empty?
                xforms = config.transformer_fields
                  .map { |field| "#{field}_xform".to_sym }
                  .map { |setting| config.send(setting) }
                  .compact
                transform do |row|
                  xforms.each do |xform|
                    row = xform.process(row)
                  end
                  row
                end
              end

              rename_map = {
                chat: :viewerscontributionnote,
                culture: :objectproductionpeople,
                description: :briefdescription,
                medium: :materialtechniquedescription,
                notes: :comment,
                objectcount: :numberofobjects
              }
              unless bind.receiver.send(:merges_dimensions?)
                unless Tms::Dimensions.migrate_secondary_unit_vals
                  transform do |row|
                    display = row[:dimensions]
                    row[:dimensions] = display.sub(/ \(.*\)$/, "")
                    row
                  end
                end
                rename_map[:dimensions] = :dimensionsummary
              end
              custom_handled_fields.each { |field| rename_map.delete(field) }
              transform Rename::Fields,
                fieldmap: rename_map.merge(Tms::Objects.custom_rename_fieldmap)

              transform Delete::DelimiterOnlyFieldValues,
                fields: %w[contentnote objectproductionnote
                  objecthistorynote].map { |prefix|
                          config.send("#{prefix}_sources".to_sym)
                        }.flatten,
                delim: Tms.delim,
                treat_as_null: Tms.nullvalue

              %w[annotation nontext_inscription text_inscription].each do |type|
                sources = config.send("#{type}_source_fields".to_sym)
                targets = config.send("#{type}_target_fields".to_sym)
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
                delim: Tms.delim,
                delete_sources: true

              unless Tms::Objects.named_coll_fields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: Tms::Objects.named_coll_fields,
                  target: :namedcollection,
                  delim: Tms.delim,
                  delete_sources: true
              end

              %w[
                contentnote objectproductionnote
                objecthistorynote
              ].each do |target|
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.send("#{target}_sources".to_sym),
                  target: target,
                  delim: config.send("#{target}_delim".to_sym),
                  delete_sources: true
              end
            end
          end
        end
      end
    end
  end
end
