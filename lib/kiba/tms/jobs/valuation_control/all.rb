# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ValuationControl
        module All
          module_function

          def job
            return if sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :valuation_control__all
              },
              transformer: xforms
            )
          end

          def sources
            %i[
               valuation_control__from_obj_insurance
               valuation_control__from_accession_lot
              ].select{ |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::IdGenerator,
                prefix: 'VC',
                id_source: :idbase,
                id_target: :valuationcontrolrefnumber
              transform Append::NilFields,
                fields: config.multi_source_normalizer.get_fields
            end
          end
        end
      end
    end
  end
end
