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

              # Not all rows have structured date data that was processed via DateFromParts.
              # This moves any `remarks` values beginning with 4 digits to the `date` field
              transform do |row|
                date = row[:date]
                next row unless date.blank?

                remark = row[:remarks]
                next row if remark.blank?
                next row unless remark.start_with?(/\d{4}|\d{1,2}(\/|-)/)

                row[:date] = remark
                row[:remarks] = nil

                row
              end

              # This affects any remarks starting with 'active'. It changes `datedescription` to 'Active Dates' and
              #   moves the remaining `remarks` value after 'active ' to the `date` field (if `date` is blank)
              transform do |row|
                row[:warn] = nil
                remark = row[:remarks]
                next row if remark.blank?
                next row unless remark.start_with?('active ')

                row[:datedescription] = 'Active Dates'
                date = row[:date]
                if date.blank?
                  row[:date] = remark.delete_prefix('active ')
                  row[:remarks] = nil
                else
                  row[:warn] = 'active date in remarks, some other date value in date'
                end
                
                row
              end

              ['active', 'active dates'].each do |typestr|
                transform Clean::RegexpFindReplaceFieldVals,
                  fields: :datedescription,
                  find: "^ *#{typestr} *$",
                  replace: 'active',
                  casesensitive: false
              end

              ['birth', 'birth date', 'birth year', 'birthdate', 'birthday', 'born', 'founded'].each do |typestr|
                transform Clean::RegexpFindReplaceFieldVals,
                  fields: :datedescription,
                  find: "^ *#{typestr} *$",
                  replace: 'birth',
                  casesensitive: false
              end

              ['dead', 'death', 'death date', 'death day', 'death year', 'deathdate', 'deathday', 'died'].each do |typestr|
                transform Clean::RegexpFindReplaceFieldVals,
                  fields: :datedescription,
                  find: "^ *#{typestr} *$",
                  replace: 'death',
                  casesensitive: false
              end

              # misc fixes for remarks/date
              transform do |row|
                date = row[:date]
                next row unless date.blank?

                remark = row[:remarks]
                next row if remark.blank?

                #if starts with month abbrev, is date
                Date::ABBR_MONTHNAMES.compact.map(&:downcase).each do |abbr|
                  if remark.downcase.start_with?(abbr)
                    row[:date] = remark
                    row[:remarks] = nil
                    next row
                  end
                end

                # if partial or approximate indicator, date
                %w[after approximately around before c. ca. circa].each do |term|
                  if remark.downcase.start_with?(term)
                    row[:date] = remark
                    row[:remarks] = nil
                    next row
                  end
                end
                
                datetype = row[:datedescription]
                next row if datetype.blank?

                case datetype
                when 'birth'
                  if remark.downcase.start_with?('born')
                    row[:date] = remark.delete_prefix('born ')
                    row[:remarks] = nil
                    next row
                  end
                when 'death'
                  if remark.downcase.start_with?('died')
                    row[:date] = remark.delete_prefix('died ')
                    row[:remarks] = nil
                    next row
                  end
                end

                row
              end
              
              # warn if no date value
              transform do |row|
                date = row[:date]
                next row unless date.blank?
                
                warn = row[:warn]
                
                row[:warn] = [warn, 'No date value'].compact.join('; ')  
                row
              end

              # warn if no date type, or unknown date type
              transform do |row|
                datetype = row[:datedescription]
                next row if KNOWN_TYPES.any?(datetype)
                
                warn = row[:warn]
                
                if datetype.blank?
                  row[:warn] = [warn, 'No date type'].compact.join('; ')  
                else
                  row[:warn] = [warn, 'Unknown date type'].compact.join('; ')
                end

                row
              end
            end
          end
        end
      end
    end
  end
end
