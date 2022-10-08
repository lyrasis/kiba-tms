# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module Worksheet
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: source,
                destination: :name_type_cleanup__worksheet
              },
              transformer: xforms
            )
          end

          def source
            if config.done
              :name_type_cleanup__supplied_cleanup_merged
            else
              :name_type_cleanup__from_base_data
            end
          end

          def xforms
            Kiba.job_segment do
              transform Rename::Field, from: :contype, to: :authoritytype
              transform Append::NilFields, fields: %i[correctauthoritytype correctname]
              transform Clean::RegexpFindReplaceFieldVals, fields: :all, find: '%QUOT%', replace: '"'
            end
          end
        end
      end
    end
  end
end
