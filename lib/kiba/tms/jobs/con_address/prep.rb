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
                lookup: :nameclean__by_constituentid
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Merge::MultiRowLookup,
                lookup: nameclean__by_constituentid,
                keycolumn: :constituentid,
                fieldmap: { matches_constituent: :constituentid }
              transform Tms::Transforms::ConAddress::AddRetentionFlag
            end
            
          end
        end
      end
    end
  end
end
