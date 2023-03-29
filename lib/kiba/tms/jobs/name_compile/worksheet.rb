# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module Worksheet
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: %i[
                           name_compile__unique_split_main
                           name_compile__unique_split_note
                           name_compile__unique_split_contact
                           name_compile__unique_split_variant
                          ],
                destination: :name_compile__worksheet,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :name_compile__previous_worksheet_compile if config.done
            base
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Rename::Field, from: :contype, to: :authority
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[authority name constituentid relation_type
                            termsource],
                target: :cleanupid,
                sep: ' ',
                delete_sources: false

              if config.done
                transform do |row|
                  src = row[:termsource]
                  next row unless src == 'clientcleanup'

                  row[:termsource] = 'clientcleanupprev'
                  row
                end
                transform Count::MatchingRowsInLookup,
                  lookup: name_compile__previous_worksheet_compile,
                  keycolumn: :cleanupid,
                  targetfield: :ct,
                  result_type: :int
                transform do |row|
                  if row[:termsource] == 'clientcleanupprev'
                    row[:to_review] = 'n'
                  elsif row[:ct] == 0
                    row[:to_review] = 'y'
                  else
                    row[:to_review] = 'n'
                  end
                  row.delete(:ct)
                  row
                end
                transform Clean::RegexpFindReplaceFieldVals,
                  fields: :to_review,
                  find: '^n$',
                  replace: ''
              end
            end
          end
        end
      end
    end
  end
end
