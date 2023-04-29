# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAddress
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_address,
                destination: :prep__con_address,
                lookup: :names__by_constituentid
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner

              transform Merge::MultiRowLookup,
                lookup: names__by_constituentid,
                keycolumn: :constituentid,
                fieldmap: {matches_constituent: :constituentid}
              transform Tms::Transforms::ConAddress::AddRetentionFlag
            end
          end
        end
      end
    end
  end
end
