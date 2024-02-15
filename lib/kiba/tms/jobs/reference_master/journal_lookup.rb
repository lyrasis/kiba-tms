# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module JournalLookup
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :reference_master__journals,
                destination: :reference_master__journal_lookup,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if config.headings_needed && config.headings_returned
              base << :reference_master__headings_returned
            end
            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              lookups = job.send(:lookups)

              if lookups.any?(:reference_master__headings_returned)
                transform Merge::MultiRowLookup,
                  lookup: reference_master__headings_returned,
                  keycolumn: :referenceid,
                  fieldmap: {
                    heading: :heading,
                    drop: :drop
                  }
              end
            end
          end
        end
      end
    end
  end
end
