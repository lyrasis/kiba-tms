# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Citations
        module Pubdate
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :reference_master__date_base,
                destination: :citations__pubdate,
                lookup: :dates_translated__lookup
              },
              transformer: [
                Tms::DatesTranslated.merge_xforms(keycolumn: :displaydate),
                xforms
              ]
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: :displaydate
              transform Clean::DowncaseFieldValues,
                fields: %i[dateearliestsinglecertainty datelatestcertainty]
              transform Rename::Field,
                from: :heading,
                to: :termdisplayname
              transform Merge::ConstantValue,
                target: :date_field_group,
                value: "publicationDate"
            end
          end
        end
      end
    end
  end
end
