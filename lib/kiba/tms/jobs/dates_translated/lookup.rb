# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module DatesTranslated
        module Lookup
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.lookup_source_jobs,
                destination: :dates_translated__lookup
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              datefields = config.cs_date_fields

              transform Delete::Fields, fields: :warnings

              # add missing date fields to each row
              transform do |row|
                missing = datefields - row.keys
                next row if missing.empty?

                missing.each{ |field| row[field] = nil }
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
