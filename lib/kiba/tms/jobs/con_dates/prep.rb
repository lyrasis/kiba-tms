# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConDates
        module Prep
          module_function

          KNOWN_TYPES = %w[birth death active]
          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :tms__con_dates,
                destination: :prep__con_dates,
                lookup: :tms__constituents
              },
              transformer: xforms,
              helper: Tms::Constituents.dates.multisource_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields

              if Tms::Constituents.dates.initial_remarks_cleaner
                transform Tms::Constituents.dates.initial_remarks_cleaner
              end

              transform Delete::FieldValueMatchingRegexp,
                fields: %i[
                  datebegsearch monthbegsearch daybegsearch
                  dateendsearch monthendsearch dayendsearch
                ],
                match: "^0$"

              transform Tms::Transforms::DateFromParts,
                year: :datebegsearch, month: :monthbegsearch, day: :daybegsearch, target: :datebegin
              transform Tms::Transforms::DateFromParts,
                year: :dateendsearch, month: :monthendsearch, day: :dayendsearch, target: :dateend
              transform CombineValues::FromFieldsWithDelimiter, sources: %i[datebegin dateend], target: :date,
                delim: " - ", delete_sources: true

              transform Append::NilFields, fields: :warn

              Tms::Constituents.dates.cleaners.each do |cleaner|
                transform cleaner
              end

              transform Merge::ConstantValue, target: :datasource,
                value: "ConDates"
            end
          end
        end
      end
    end
  end
end
