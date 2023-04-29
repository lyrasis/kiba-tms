# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConDates
        module Postmig
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_dates,
                destination: :con_dates__postmig,
                lookup: :prep__constituents
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: prep__constituents,
                keycolumn: :constituentid,
                fieldmap: {
                  name: Tms::Constituents.preferred_name_field,
                  authority: :contype
                }
            end
          end
        end
      end
    end
  end
end
