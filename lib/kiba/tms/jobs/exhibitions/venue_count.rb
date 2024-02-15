# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Exhibitions
        module VenueCount
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__exhibitions,
                destination: :exhibitions__venue_count,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if Tms::ExhVenuesXrefs.used?
              base << :prep__exh_venues_xrefs
            end
            base.select { |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              lookups = job.send(:lookups)

              if lookups.any?(:prep__exh_venues_xrefs)
                transform Count::MatchingRowsInLookup,
                  lookup: prep__exh_venues_xrefs,
                  keycolumn: :exhibitionid,
                  target: :venues
              else
                transform Merge::ConstantValue,
                  target: :venues,
                  value: "1"
              end
            end
          end
        end
      end
    end
  end
end
