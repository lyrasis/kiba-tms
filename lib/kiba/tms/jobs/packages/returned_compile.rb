# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Packages
        module ReturnedCompile
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.returned_file_jobs,
                destination: :packages__returned_compile,
                lookup: :packages__omitted
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::FieldsExcept,
                fields: %i[migrating packageid]

              transform Deduplicate::Table,
                field: :packageid,
                delete_field: false

              transform Merge::MultiRowLookup,
                lookup: packages__omitted,
                keycolumn: :packageid,
                fieldmap: {omit: :omit}
              transform do |row|
                omit = row[:omit]
                next row if omit.blank?

                row[:migrating] = "n"
                row
              end

              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
