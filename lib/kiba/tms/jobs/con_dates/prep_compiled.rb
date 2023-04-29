# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConDates
        module PrepCompiled
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :con_dates__compiled,
                destination: :con_dates__prep_compiled
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::FlagAll, on_field: :combined, in_field: :duplicate, explicit_no: false
              transform Deduplicate::Flag, on_field: :combined, in_field: :duplicate_subsequent, explicit_no: false, using: {}
              
              Tms::Constituents.dates.warning_generators.each do |warner|
                transform warner
              end
              
              if Tms::Constituents.dates.note_creator
                transform Tms::Constituents.dates.note_creator
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[datenote datenote_created],
                target: :datenote,
                sep: "%CR%%CR%",
                delete_sources: true

              transform do |row|
                row[:birth_foundation_date] = nil
                row[:death_dissolution_date] = nil
                duplicate = row[:duplicate_subsequent]
                next row unless duplicate.blank?
                
                type = row[:datedescription]
                next row if type.blank?
                next row unless type == "birth" || type == "death"

                date = row[:date]
                next row if date.blank?

                type == "birth" ? row[:birth_foundation_date] = date : row[:death_dissolution_date] = date
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
