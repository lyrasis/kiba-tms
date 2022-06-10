# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConDates
        module ForReview
          module_function

          KNOWN_TYPES = %w[birth death active]
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_dates,
                destination: :con_dates__for_review,
                lookup: :tms__constituents
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: tms__constituents,
                keycolumn: :constituentid,
                fieldmap: { constituentname: Tms.constituents.preferred_name_field }
            end
          end
        end
      end
    end
  end
end
