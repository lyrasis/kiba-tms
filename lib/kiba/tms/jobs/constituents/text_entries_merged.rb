# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module TextEntriesMerged
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__constituents,
                destination: :constituents__text_entries_merged,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if Tms::TextEntries.for?(config.table_name)
              base << :text_entries_for__constituents
            end
            base
          end

          def xforms
            Kiba.job_segment do
              temerger = Tms::TextEntries.for_constituents_merge
              if Tms::TextEntries.for?(config.table_name) && temerger
                transform temerger,
                  lookup: text_entries_for__constituents
              end
            end
          end
        end
      end
    end
  end
end
