# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module NotMatchedToRecord
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_files__file_path_lookup,
                destination: :media_files__not_matched_to_record,
                lookup: :media_files__migrating
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::FieldMatchRegexp,
                action: :reject,
                field: :filepath,
                match: '\/$'
              transform Merge::MultiRowLookup,
                lookup: media_files__migrating,
                keycolumn: :filepath,
                fieldmap: {
                  matched: :identificationnumber
                },
                delim: Tms.delim
              transform FilterRows::FieldPopulated,
                action: :reject,
                field: :matched
              transform Delete::Fields, fields: :matched
              transform do |row|
                val = row[:filepath]
                next row if val.nil? || val.empty?

                row[:filepath] = val.delete_prefix(config.s3_url_base)
                row
              end
            end
          end
        end
      end
    end
  end
end
