# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module TemptextMappedForMerge
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_locations__temptext_mapped,
                destination: :obj_locations__temptext_mapped_for_merge
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::Fields,
                fields: %i[loc1 objectnumber transdate dateout]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[temptext loc3 loc5],
                target: :lookup,
                sep: " ",
                delete_sources: false,
                prepend_source_field_name: true
            end
          end
        end
      end
    end
  end
end
