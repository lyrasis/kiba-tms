# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Exhibitions
        module MergeExhObjInfo
          module_function

          def job
            return unless config.used

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :exhibitions__shaped,
                destination: :exhibitions__merge_exh_obj_info
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              if Tms::Exhibitions.migrate_exh_obj_info
                warn("#{job.send(:name)}: Implement merge of object details")
              else
                # do nothing
              end
            end
          end
        end
      end
    end
  end
end
