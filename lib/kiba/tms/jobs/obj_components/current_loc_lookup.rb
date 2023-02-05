# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module CurrentLocLookup
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_components,
                destination: :obj_components__current_loc_lookup,
                lookup: :obj_locations__migrating
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: :currentobjlocid
              transform Merge::MultiRowLookup,
                lookup: obj_locations__migrating,
                keycolumn: :currentobjlocid,
                fieldmap: {fullfingerprint: :fullfingerprint}
              transform Delete::Fields, fields: :currentobjlocid
              transform Deduplicate::Table, field: :fullfingerprint
            end
          end
        end
      end
    end
  end
end
