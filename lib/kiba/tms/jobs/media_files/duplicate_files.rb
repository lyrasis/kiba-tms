# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module DuplicateFiles
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_files__migratable,
                destination: :media_files__duplicate_files,
                lookup: :tms__media_files
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::FlagAll,
                on_field: :fullpath,
                in_field: :duplicatefp,
                explicit_no: false
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :duplicatefp
              transform Delete::Fields,
                fields: %i[path filename filesize memorysize duplicatefp
                           duplicate_filename duplicate_fullpath checksum
                           rend_thumbpath rend_thumbfilename ms_publishto]
              transform Delete::EmptyFields

              transform Merge::MultiRowLookup,
                lookup: tms__media_files,
                keycolumn: :fileid,
                fieldmap: {file_entered_date: :entereddate}
            end
          end
        end
      end
    end
  end
end
