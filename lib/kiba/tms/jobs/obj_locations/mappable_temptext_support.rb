# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module MappableTemptextSupport
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_locations,
                destination: :obj_locations__mappable_temptext_support,
                lookup: :prep__locations
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :temptext

              transform Delete::FieldsExcept,
                fields: (
                config.fulllocid_fields +
                  %i[objectnumber transdate dateout temptext]
              ).uniq

              transform Merge::MultiRowLookup,
                lookup: prep__locations,
                keycolumn: :locationid,
                fieldmap: {loc1: :tmslocationstring}
              transform Delete::Fields, fields: :locationid
              transform Rename::Fields, fieldmap: {
                loclevel: :loc3,
                sublevel: :loc5
              }
            end
          end
        end
      end
    end
  end
end
