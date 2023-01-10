# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_locations,
                destination: :prep__obj_locations,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = [:obj_components__with_object_numbers_by_compid]
            base << :prep__loc_purposes if Tms::LocPurposes.used?
            base << :prep__trans_status if Tms::TransStatus.used?
            base << :prep__trans_codes if Tms::TransCodes.used?
            if config.temptext_mapping_done
              base << :obj_locations__temptext_mapped_for_merge
            end
            base
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end
              if config.drop_inactive
                transform FilterRows::FieldEqualTo,
                  action: :reject,
                  field: :inactive,
                  value: '1'
              end
              if config.fields.any?(:loclevel)
                transform Delete::FieldValueMatchingRegexp,
                  fields: %i[loclevel],
                  match: '^0$'
              end
              if config.fields.any?(:dateout)
                transform Delete::FieldValueMatchingRegexp,
                  fields: %i[dateout],
                  match: '^9999-12-31'
              end
              if config.fields.any?(:tempticklerdate)
                transform Delete::FieldValueMatchingRegexp,
                  fields: %i[dateout],
                  match: '^1900'
              end
              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :objlocationid,
                value: '-1'
              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :locationid,
                value: '-1'

              transform Tms.data_cleaner if Tms.data_cleaner

              %i[approver handler requestedby].each do |field|
                next unless config.fields.any?(field)

                transform Tms::Transforms::DeleteNoValueTypes, field: field
              end

              # renames fulllocid_fields to their hierarchical positions
              transform Rename::Fields,
                fieldmap: config.hier_lvl_lookup

              if config.temptext_mapping_done
                transform Tms::Transforms::ObjLocations::AddTemptextid,
                  target: :lookupid
                transform Merge::MultiRowLookup,
                  lookup: obj_locations__temptext_mapped_for_merge,
                  keycolumn: :lookupid,
                  fieldmap: {
                    ttmapping: :mapping,
                    ttcorrect: :corrected_value
                  }
                transform Tms::Transforms::ObjLocations::TemptextMappings
                if config.temptext_mapping_post_xform
                  transform config.temptext_mapping_post_xform
                end
              end

              transform Tms::Transforms::ObjLocations::AddFulllocid

              transform Merge::MultiRowLookup,
                lookup: obj_components__with_object_numbers_by_compid,
                keycolumn: :componentid,
                fieldmap: {
                  objectnumber: :componentnumber,
                },
                delim: Tms.delim

              if Tms::LocPurposes.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__loc_purposes,
                  keycolumn: :locpurposeid,
                  fieldmap: {
                    location_purpose: :locpurpose,
                  },
                  delim: Tms.delim
              end
              transform Delete::Fields, fields: %i[componentid locpurposeid]

              transform Replace::FieldValueWithStaticMapping,
                source: :tempflag,
                target: :is_temp?,
                mapping: Tms.boolean_yn_mapping

              unless config.drop_inactive
                transform Tms::Transforms::ObjLocations::HandleInactive
              end

              if Tms::TransStatus.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__trans_status,
                  keycolumn: :transstatusid,
                  fieldmap: {
                    transport_status: :transstatus,
                  },
                  delim: Tms.delim
              end
              if Tms::TransCodes.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__trans_codes,
                  keycolumn: :transcodeid,
                  fieldmap: {
                    transport_type: :transcode,
                  },
                  delim: Tms.delim
              end
              transform Delete::Fields, fields: %i[transstatusid transcodeid]
            end
          end
        end
      end
    end
  end
end
