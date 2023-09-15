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
                destination: :prep__alt_nums
              },
              transformer: xforms
            )
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
                replace: ""
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: "^(%CR%%(CR|LF)%)+",
                replace: ""
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: "(%CR%%(CR|LF)%)+$",
                replace: ""

              transform config.initial_cleaner if config.initial_cleaner

              if config.description_cleaner
                transform config.description_cleaner
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[tablename description],
                target: :lookupkey,
                delim: " ",
                delete_sources: false
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
