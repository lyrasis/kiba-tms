# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module PrepRemain
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_locations,
                destination: :obj_locations__grouped
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




              unless config.drop_inactive
                transform Tms::Transforms::ObjLocations::HandleInactive
              end

            end
          end
        end
      end
    end
  end
end
