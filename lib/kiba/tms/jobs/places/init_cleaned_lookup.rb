# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module InitCleanedLookup
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :places__init_cleaned_lookup
              },
              transformer: xforms
            )
          end

          def sources
            base = %i[
              places__uniq_hierarchical
              places__uniq_nonhier
            ]
            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Explode::RowsFromMultivalField,
                field: :norm_combineds,
                delim: config.norm_fingerprint_delim
              transform Rename::Field,
                from: :norm_combineds,
                to: :norm_combined
            end
          end
        end
      end
    end
  end
end
