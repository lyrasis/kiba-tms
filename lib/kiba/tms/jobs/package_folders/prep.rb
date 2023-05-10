# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module PackageFolders
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__package_folders,
                destination: :prep__package_folders,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            if Tms::FolderTypes.used?
              [:tms__folder_types]
            else
              []
            end
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

              if Tms::FolderTypes.used?
                transform Merge::MultiRowLookup,
                  lookup: tms__folder_types,
                  keycolumn: :foldertypeid,
                  fieldmap: {foldertype: :foldertype}
              end
              transform Delete::Fields, fields: :foldertypeid
            end
          end
        end
      end
    end
  end
end
