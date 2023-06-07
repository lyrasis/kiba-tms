# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module Worksheet
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__cleaned_unique,
                destination: :places__worksheet,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :places__returned_compile if config.cleanup_done
            base.select{ |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

              if config.cleanup_done && lookups.any?(
                :places__returned_compile
              )
                transform do |row|
                  row[:to_review] = nil
                  norm = row[:norm_combineds]
                  next row if norm.blank?

                  known = norm.split(config.norm_fingerprint_delim)
                    .map{ |norm| places__returned_compile.key?(norm) }
                    .all?
                  next row if known

                  row[:to_review] = "y"
                  row
                end

              end

              transform Fingerprint::Add,
                fields: config.source_fields,
                target: :clean_fingerprint
            end
          end
        end
      end
    end
  end
end
