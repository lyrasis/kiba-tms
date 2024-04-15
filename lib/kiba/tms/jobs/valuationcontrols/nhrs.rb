# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Valuationcontrols
        module Nhrs
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :valuationcontrols__nhrs
              },
              transformer: xforms
            )
          end

          def sources
            %i[
              valuationcontrols__nhr_acq_accession_lot
              valuationcontrols__nhr_obj_accession_lot
              acq_num_acq__acq_valuation_rel
              linked_set_acq__acq_valuation_rel
              lot_num_acq__acq_valuation_rel
              one_to_one_acq__acq_valuation_rel
              valuationcontrols__nhr_obj
            ].select { |job| Tms.job_output?(job) }
          end

          def xforms
            Kiba.job_segment do
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[item1_id item2_id],
                target: :combined,
                delim: " ",
                delete_sources: false
              transform Deduplicate::Table,
                field: :combined,
                delete_field: true
            end
          end
        end
      end
    end
  end
end
