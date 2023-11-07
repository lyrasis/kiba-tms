# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConservationTreatments
        module FromCondLineItems
          module_function

          def job
            return if sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :conservation_treatments__from_cond_line_items,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def sources
            base = [:cond_line_items__to_conservation]
            base.select { |key| Tms.job_output?(key) }
          end

          def lookups
            base = [:conditions__cspace]
            base.select { |key| Tms.job_output?(key) }
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields, fields: :briefdescription
              transform Prepend::ToFieldValue,
                field: :durationdays,
                value: "Treatment duration (days): "
              transform Rename::Fields, fieldmap: {
                proposal: :proposedtreatment
              }
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[treatment durationdays],
                target: :treatmentsummary,
                delim: Tms.notedelim,
                delete_sources: true

              transform Merge::MultiRowLookup,
                lookup: conditions__cspace,
                keycolumn: :conditionid,
                fieldmap: {
                  tablename: :tablename,
                  recordnumber: :recordnumber,
                  conditioncheckrefnumber: :conditioncheckrefnumber
                }
              transform Merge::ConstantValue,
                target: :datasource,
                value: "CondLineItems"
            end
          end
        end
      end
    end
  end
end
