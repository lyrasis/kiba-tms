# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module MergeExternalTables
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__prep_clean,
                destination: :constituents__merge_external_tables,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              if Tms::ThesXrefs.for?(config.table_name) &&
                  Tms::ThesXrefsForConstituents.merger_xforms
                Tms::ThesXrefsForConstituents.merger_xforms.each do |xform|
                  transform xform
                end
              end

              if Tms::AltNums.for?(config.table_name) &&
                  Tms::AltNumsForConstituents.merger_xforms
                Tms::AltNumsForConstituents.merger_xforms.each do |xform|
                  transform xform
                end
              end

              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
