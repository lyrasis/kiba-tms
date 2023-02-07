# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ValuationControl
        module Nhrs
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :valuation_control__nhrs
              },
              transformer: xforms
            )
          end

          def sources
            %i[
               valuation_control__nhr_acq_accession_lot
               valuation_control__nhr_obj_accession_lot
               acq_num_acq__acq_valuation_rel
               linked_set_acq__acq_valuation_rel
               lot_num_acq__acq_valuation_rel
               one_to_one_acq__acq_valuation_rel
               valuation_control__nhr_obj
              ].select{ |job| Tms.job_output?(job) }
          end

          def xforms
            Kiba.job_segment do
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[item1_id item2_id],
                target: :combined,
                sep: ' ',
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
