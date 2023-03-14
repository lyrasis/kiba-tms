# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Packages
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__packages,
                destination: :prep__packages,
                lookup: %i[
                           tms__package_folder_xrefs
                           prep__package_folders
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
                lookup: tms__package_folder_xrefs,
                keycolumn: :packageid,
                fieldmap: {folderid: :folderid}
              transform Merge::MultiRowLookup,
                lookup: prep__package_folders,
                keycolumn: :folderid,
                fieldmap: {
                  foldername: :foldername,
                  folderdesc: :folderdesc,
                  foldertype: :foldertype
                }
            end
          end
        end
      end
    end
  end
end
