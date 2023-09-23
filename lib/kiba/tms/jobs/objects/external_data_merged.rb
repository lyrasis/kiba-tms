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

              if Tms::AltNums.for?("Objects") &&
                  Tms::AltNumsForObjects.merger_xforms
                Tms::AltNumsForObjects.merger_xforms.each do |xform|
                  transform xform
                end
              end

              if Tms::StatusFlags.for?("Objects") &&
                  Tms::StatusFlagsForObjects.merger_xforms
                Tms::StatusFlagsForObjects.merger_xforms.each do |xform|
                  transform xform
                end
              end

              if Tms::TextEntries.for?("Objects") &&
                  Tms::TextEntriesForObjects.merger_xforms
                Tms::TextEntriesForObjects.merger_xforms.each do |xform|
                  transform xform
                end
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
            end
          end
        end
      end
    end
  end
end
