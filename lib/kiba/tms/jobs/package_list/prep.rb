# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module PackageList
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__package_list,
                destination: :prep__package_list,
                lookup: %i[
                  packages__shaped
                  objects__numbers_cleaned
                ]
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

              transform Merge::MultiRowLookup,
                lookup: packages__shaped,
                keycolumn: :packageid,
                fieldmap: {package: :title},
                delim: Tms.delim
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :package
              transform Merge::MultiRowLookup,
                lookup: objects__numbers_cleaned,
                keycolumn: :id,
                fieldmap: {objectnumber: :objectnumber},
                conditions: ->(r, rows) do
                  return [] unless r[:tablename] == "Objects"

                  rows
                end
            end
          end
        end
      end
    end
  end
end
