# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConDates
        module ForReview
          module_function

          def job
            return unless Tms::Table::List.include?("ConDates")

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :con_dates__prep_compiled,
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
                fieldmap: {constituentname: Tms::Constituents.preferred_name_field}

              if Tms::Constituents.dates.date_parser
                transform Tms::Constituents.dates.date_parser
              end
            end
          end
        end
      end
    end
  end
end
