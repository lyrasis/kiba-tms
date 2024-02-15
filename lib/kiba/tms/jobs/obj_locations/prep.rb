# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module Prep
          module_function

          def desc
            "- Deletes omitted fields\n"\
              "- Deletes empty-equivalent field values from :loclevel, "\
              ":dateout, :tempticklerdate, :approver, :handler, "\
              ":requestedby\n"\
              "- Removes timestamps from :transdate, :dateout\n"\
              "- Runs client-specific initial data cleaner if configured\n"\
              "- Rename location detail fields to hierarchical level names\n"\
              "- Merge in client-mapped temptext mappings\n"\
              "- Add :fulllocid for :location value\n"\
              "- Merge in :homelocation from ObjComponents\n"\
              "- Create :fullhomelocid\n"\
              "- ADDS ROW FINGERPRINT for collapsing rows with identical data "\
              "into one LMI procedure\n"\
              "- Merge in human readable :objectnumber, :location_purpose "\
              ":transport_status, :transport_type values\n"\
              "- Converts numeric :tempflag field value to y/nil in :is_temp\n"
          end

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_locations,
                destination: :prep__obj_locations,
                lookup: lookups
              },
              # Transforms are split up because the general xforms are reused by
              #   ObjComponents::ProblemComponentLmi
              transformer: [
                remove_problem_component_locs,
                xforms
              ]
            )
          end

          def lookups
            base = %i[
              obj_components__with_object_numbers_by_compid
            ]
            base << :prep__loc_purposes if Tms::LocPurposes.used?
            base << :prep__trans_status if Tms::TransStatus.used?
            base << :prep__trans_codes if Tms::TransCodes.used?
            if config.temptext_mapping_done
              base << :obj_locations__temptext_mapped_for_merge
            end
            base << :obj_components__problem_components
            base.select { |job| Tms.job_output?(job) }
          end

          def remove_problem_component_locs
            bind = binding

            Kiba.job_segment do
              lookups = bind.receiver.send(:lookups)
              if lookups.any?(:obj_components__problem_components)
                transform Merge::MultiRowLookup,
                  lookup: obj_components__problem_components,
                  keycolumn: :componentid,
                  fieldmap: {problem: :componentnumber}
                transform FilterRows::FieldPopulated,
                  action: :reject,
                  field: :problem
                transform Delete::Fields, fields: :problem
              end
            end
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

              # Clear/clean data that should not be included as fingerprint
              #   values
              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              if config.fields.any?(:loclevel)
                transform Delete::FieldValueMatchingRegexp,
                  fields: %i[loclevel],
                  match: "^0$"
              end
              if config.fields.any?(:dateout)
                transform Delete::FieldValueMatchingRegexp,
                  fields: %i[dateout],
                  match: "^9999-12-31"
              end
              if config.fields.any?(:tempticklerdate)
                transform Delete::FieldValueMatchingRegexp,
                  fields: %i[dateout],
                  match: "^1900"
              end

              transform Tms::Transforms::DeleteTimestamps,
                fields: %i[transdate dateout]
              transform Clean::RegexpFindReplaceFieldVals,
                fields: %i[approver handler requestedby],
                find: Tms.no_value_type_pattern,
                replace: ""

              transform Tms.data_cleaner if Tms.data_cleaner

              unless config.hier_lvl_lookup.empty?
                # renames fulllocid_fields to their hierarchical positions
                transform Rename::Fields,
                  fieldmap: config.hier_lvl_lookup
              end

              if config.temptext_mapping_done
                transform Tms::Transforms::ObjLocations::AddTemptextid,
                  target: :lookupid
                if lookups.any?(:obj_locations__temptext_mapped_for_merge)
                  transform Merge::MultiRowLookup,
                    lookup: obj_locations__temptext_mapped_for_merge,
                    keycolumn: :lookupid,
                    fieldmap: {
                      ttmapping: :mapping,
                      ttcorrect: :corrected_value
                    }
                end
                transform Tms::Transforms::ObjLocations::TemptextMappings
                if config.temptext_mapping_post_xform
                  transform config.temptext_mapping_post_xform
                end
              end

              transform Tms::Transforms::ObjLocations::AddFulllocid

              if lookups.any?(:obj_components__with_object_numbers_by_compid)
                transform Merge::MultiRowLookup,
                  lookup: obj_components__with_object_numbers_by_compid,
                  keycolumn: :componentid,
                  fieldmap: {
                    objectnumber: :componentnumber,
                    homelocationid: :homelocationid
                  },
                  delim: Tms.delim
              end
              transform Tms::Transforms::ObjLocations::AddFulllocid,
                source: :homelocationid,
                target: :fullhomelocid

              transform Tms::Transforms::ObjLocations::AddFingerprint,
                sources: config.fingerprint_fields

              # Merge in data for table readability
              if lookups.any?(:prep__loc_purposes)
                transform Merge::MultiRowLookup,
                  lookup: prep__loc_purposes,
                  keycolumn: :locpurposeid,
                  fieldmap: {
                    location_purpose: :locpurpose
                  },
                  delim: Tms.delim
              end
              if lookups.any?(:prep__trans_status)
                transform Merge::MultiRowLookup,
                  lookup: prep__trans_status,
                  keycolumn: :transstatusid,
                  fieldmap: {
                    transport_status: :transstatus
                  },
                  delim: Tms.delim
              end
              if lookups.any?(:prep__trans_codes)
                transform Merge::MultiRowLookup,
                  lookup: prep__trans_codes,
                  keycolumn: :transcodeid,
                  fieldmap: {
                    transport_type: :transcode
                  },
                  delim: Tms.delim
              end
              transform Delete::Fields,
                fields: %i[locpurposeid transstatusid transcodeid]

              transform Replace::FieldValueWithStaticMapping,
                source: :tempflag,
                target: :is_temp,
                mapping: Tms.boolean_yn_mapping
              transform Delete::FieldValueMatchingRegexp,
                fields: %i[is_temp],
                match: "^n$"
            end
          end
        end
      end
    end
  end
end
