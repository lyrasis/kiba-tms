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
              transformer: [
                # xforms,
                config.post_merge_xforms,
                consistency
              ].compact
            )
          end

          def lookups
            base = []
            # base << :prep__object_names if Tms::ObjectNames.used?
            # base << :prep__obj_titles if Tms::ObjTitles.used?
            # if config.dimensions_to_merge?
            #   base << :dim_item_elem_xrefs_for__objects
            # end
            # if Tms::ObjComponents.merging_text_entries?
            #   base << :obj_components__with_object_numbers
            # end
            # if Tms::LinkedSetAcq.used?
            #   base << :linked_set_acq__object_statuses
            # end
            # if Tms::StatusFlags.used? && Tms::StatusFlags.for?("Objects")
            #   base << :status_flags_for__objects
            # end
            # if Tms::ObjGeography.used?
            #   base << :prep__obj_geography
            #   base << :places__final_cleaned_lookup
            # end
            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              if Tms::ConRefs.for?("Objects")
                if config.con_ref_name_merge_rules
                  transform Tms::Transforms::ConRefs::Merger,
                    into: config,
                    keycolumn: :objectid
                end
                Tms::ConRefsForObjects.merger_xforms&.each { |xform|
                  transform xform
                }
              end

              transform Rename::Field,
                from: :objectname,
                to: :obj_objectname
              if Tms::ObjectNames.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__object_names,
                  keycolumn: :objectid,
                  fieldmap: {
                    on_objectname: :objectname,
                    on_objectnametype: :objectnametype,
                    on_objectnamelanguage: :language,
                    on_objectnamenote: :remarks
                  },
                  sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i),
                  null_placeholder: "%NULLVALUE%"
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
                transform Tms::Transforms::ObjContext::MergeXforms
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

              if Tms::StatusFlags.used? && Tms::StatusFlags.for?("Objects")
                transform Merge::MultiRowLookup,
                  lookup: status_flags_for__objects,
                  keycolumn: :objectid,
                  fieldmap: {statusflag: :flaglabel},
                  delim: Tms.delim,
                  sorter: Lookup::RowSorter.new(
                    on: :sort, as: :to_i
                  ),
                  multikey: true
              end

              if Tms::TextEntries.for?("Objects") &&
                  Tms::TextEntriesForObjects.merger_xforms
                Tms::TextEntriesForObjects.merger_xforms.each do |xform|
                  transform xform
                end
              end

              if Tms::ThesXrefs.used? &&
                  Tms::ThesXrefs.for?("Objects") &&
                  Tms::ThesXrefsForObjects.merger_xforms
                Tms::ThesXrefsForObjects.merger_xforms.each do |xform|
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

              if Tms::ObjGeography.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__obj_geography,
                  keycolumn: :objectid,
                  fieldmap: {
                    place_made_orig_combined: :orig_combined
                  },
                  conditions: ->(_r, rows) do
                    rows.select { |row| row[:geocode] == "Place Made" }
                  end
                transform Merge::MultiRowLookup,
                  lookup: prep__obj_geography,
                  keycolumn: :objectid,
                  fieldmap: {
                    other_place_orig_combined: :orig_combined
                  },
                  conditions: ->(_r, rows) do
                    rows.reject { |row| row[:geocode] == "Place Made" }
                  end

                transform Merge::MultiRowLookup,
                  lookup: places__final_cleaned_lookup,
                  keycolumn: :place_made_orig_combined,
                  fieldmap: {
                    made_assocplace: :place,
                    made_assocplacenote: :note
                  },
                  null_placeholder: "%NULLVALUE%",
                  constantmap: {made_assocplacetype: "place made"},
                  multikey: true
                transform Merge::MultiRowLookup,
                  lookup: places__final_cleaned_lookup,
                  keycolumn: :other_place_orig_combined,
                  fieldmap: {
                    other_assocplace: :place,
                    other_assocplacenote: :note
                  },
                  constantmap: {other_assocplacetype: "%NULLVALUE%"},
                  multikey: true
                transform Delete::Fields,
                  fields: %i[place_made_orig_combined other_place_orig_combined]
              end
            end
          end

          def consistency
            Kiba.job_segment do
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
