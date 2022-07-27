# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__alt_nums,
                destination: :prep__alt_nums,
                lookup: %i[
                           tms__constituents
                           tms__objects
                           ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::TmsTableNames
              transform Rename::Fields, fieldmap: {
                id: :recordid,
                altnumid: :sort
              }
              transform Clean::RegexpFindReplaceFieldVals, fields: :description, find: '\\\\n', replace: ''
              transform Clean::RegexpFindReplaceFieldVals, fields: :all, find: '^(%CR%%LF%)+', replace: ''
              transform Clean::RegexpFindReplaceFieldVals, fields: :all, find: '(%CR%%LF%)+$', replace: ''
              transform Merge::MultiRowLookup,
                lookup: tms__constituents,
                keycolumn: :recordid,
                fieldmap: {constituent: Tms::Constituents.preferred_name_field},
                conditions: ->(origrow, mergerows) do
                  return [] unless origrow[:tablename] == 'Constituents'
                  
                  mergerows
                end
              transform Merge::MultiRowLookup,
                lookup: tms__objects,
                keycolumn: :recordid,
                fieldmap: {object: :objectnumber},
                conditions: ->(origrow, mergerows) do
                  return [] unless origrow[:tablename] == 'Objects'
                  
                  mergerows
                end
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[constituent object],
                target: :targetrecord,
                sep: '',
                delete_sources: true

              
              transform Tms::AltNums.description_cleaner if Tms::AltNums.description_cleaner
            end
          end
        end
      end
    end
  end
end
