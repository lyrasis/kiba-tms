# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__alt_nums,
                destination: :prep__alt_nums,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if config.target_tables.any?('Constituents')
              base << :tms__constituents
            end
            if config.target_tables.any?('Objects')
              base << :objects__numbers_cleaned
            end
            if config.target_tables.any?('ReferenceMaster')
              base << :tms__reference_master
            end
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner
              transform Tms::Transforms::TmsTableNames
              transform Rename::Fields, fieldmap: {
                id: :recordid,
                altnumid: :sort
              }
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :description,
                find: '\\\\n',
                replace: ''
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: '^(%CR%%(CR|LF)%)+',
                replace: ''
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: '(%CR%%(CR|LF)%)+$',
                replace: ''

              transform config.initial_cleaner if config.initial_cleaner

              recnumfields = []

              if config.target_tables.any?('Constituents')
                transform Merge::MultiRowLookup,
                  lookup: tms__constituents,
                  keycolumn: :recordid,
                  fieldmap: {constituent: Tms::Constituents.preferred_name_field},
                  conditions: ->(origrow, mergerows) do
                    return [] unless origrow[:tablename] == 'Constituents'

                    mergerows
                  end
                recnumfields << :constituent
              end
              if config.target_tables.any?('Objects')
                transform Merge::MultiRowLookup,
                  lookup: objects__numbers_cleaned,
                  keycolumn: :recordid,
                  fieldmap: {object: :objectnumber},
                  conditions: ->(origrow, mergerows) do
                    return [] unless origrow[:tablename] == 'Objects'

                    mergerows
                  end
                recnumfields << :object
              end
              if config.target_tables.any?('ReferenceMaster')
                transform Merge::MultiRowLookup,
                  lookup: tms__reference_master,
                  keycolumn: :recordid,
                  fieldmap: {reference: :title},
                  conditions: ->(origrow, mergerows) do
                    return [] unless origrow[:tablename] == 'ReferenceMaster'

                    mergerows
                  end
                recnumfields << :reference
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: recnumfields,
                target: :targetrecord,
                sep: '',
                delete_sources: true

              transform config.description_cleaner if config.description_cleaner

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[tablename description],
                target: :lookupkey,
                sep: ' ',
                delete_sources: false
            end
          end
        end
      end
    end
  end
end
