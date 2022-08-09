# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConDates
        module Prep
          module_function

          KNOWN_TYPES = %w[birth death active]
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_dates,
                destination: :prep__con_dates
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::Fields, fields: :condateid
              
              if Tms::Constituents.dates.initial_remarks_cleaner
                transform Tms::Constituents.dates.initial_remarks_cleaner
              end
              
              transform Delete::FieldValueMatchingRegexp,
                fields: %i[
                           datebegsearch monthbegsearch daybegsearch
                           dateendsearch monthendsearch dayendsearch],
                match: '^0$'

              transform Tms::Transforms::DateFromParts,
                year: :datebegsearch, month: :monthbegsearch, day: :daybegsearch, target: :datebegin
              transform Tms::Transforms::DateFromParts,
                year: :dateendsearch, month: :monthendsearch, day: :dayendsearch, target: :dateend
              transform CombineValues::FromFieldsWithDelimiter, sources: %i[datebegin dateend], target: :date,
                sep: ' - ', delete_sources: true

              transform Append::NilFields, fields: :warn
              
              Tms::Constituents.dates.cleaners.each do |cleaner|
                transform cleaner
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[constituentid datedescription],
                target: :combined,
                sep: ' ',
                delete_sources: false
              transform Deduplicate::FlagAll, on_field: :combined, in_field: :duplicate, explicit_no: false
              transform Deduplicate::Flag, on_field: :combined, in_field: :duplicate_subsequent, explicit_no: false, using: {}
              
              Tms::Constituents.dates.warning_generators.each do |warner|
                transform warner
              end

              
              if Tms::Constituents.dates.note_creator
                transform Tms::Constituents.dates.note_creator
              end

              transform do |row|
                row[:birth_foundation_date] = nil
                row[:death_dissolution_date] = nil
                duplicate = row[:duplicate_subsequent]
                next row unless duplicate.blank?
                
                type = row[:datedescription]
                next row if type.blank?
                next row unless type == 'birth' || type == 'death'

                date = row[:date]
                next row if date.blank?

                type == 'birth' ? row[:birth_foundation_date] = date : row[:death_dissolution_date] = date
                row
              end

              transform Delete::Fields, fields: %i[combined duplicate duplicate_subsequent]
            end
          end
        end
      end
    end
  end
end
