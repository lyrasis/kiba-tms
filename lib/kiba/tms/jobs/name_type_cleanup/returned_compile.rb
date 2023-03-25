# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module ReturnedCompile
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.returned_file_jobs,
                destination: :name_type_cleanup__returned_compile
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform config.returned_cleaner if config.returned_cleaner

              transform do |row|
                next row if row.key?(:to_review)

                row[:to_review] = nil
                row
              end

              # this can be taken out if we ever do a TMS migration where this
              #   process isn't changing any more during the migration!
              transform do |row|
                next row if row.key?(:cleanupid)

                row[:cleanupid] = "#{row[:constituentid]}_#{row[:name]}"
                row
              end
              %i[school sortname orig_norm nonprefnorm prefnormorig
                 nonprefnormorig namemergenorm origname].each do |field|
                transform do |row|
                  next row if row.key?(field)

                  row[field] = nil
                  row
                end
              end

              transform Deduplicate::Table,
                field: :cleanupid,
                delete_field: false
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
