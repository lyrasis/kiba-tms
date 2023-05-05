# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module Migrating
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_locations__location_names_merged,
                destination: :obj_locations__migrating
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding
            lookup = Tms.get_lookup(
              jobkey: :obj_locations__location_names_merged,
              column: :objlocationid
            )

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::AllFieldsPopulated,
                action: :keep,
                fields: %i[objectnumber location]

              if config.drop_inactive
                transform FilterRows::FieldEqualTo,
                  action: :reject,
                  field: :inactive,
                  value: "1"
                transform Delete::Fields, fields: :inactive
              end

              %i[prev next sched].each do |prefix|
                transform Merge::MultiRowLookup,
                  lookup: lookup,
                  keycolumn: "#{prefix}objlocid".to_sym,
                  fieldmap: {"#{prefix}fp".to_sym => :fingerprint}
              end
              transform Tms::Transforms::ObjLocations::AddFingerprint,
                sources: config.full_fingerprint_fields,
                target: :fullfingerprint
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[currentlocationnote loc5],
                target: :currentlocationnote,
                delim: "",
                delete_sources: true
              unless config.drop_inactive
                transform Tms::Transforms::ObjLocations::HandleInactive
              end

              transform Count::MatchingRowsInLookup,
                lookup: Tms.get_lookup(
                  jobkey: :tms__obj_components,
                  column: :currentobjlocid
                ),
                keycolumn: :objlocationid,
                targetfield: :currentct
            end
          end
        end
      end
    end
  end
end
