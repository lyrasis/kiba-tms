# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Acquisitions
        module IdsFinal
          module_function

          def job
            return if sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :acquisitions__ids_final
              },
              transformer: xforms
            )
          end

          def sources
            base = []
            if Tms::AcqNumAcq.used?
              base << :acq_num_acq__prep
            end
            if Tms::LinkedLotAcq.used?
              warn("TODO: Finish prep job for LinkedLotAcq")
            end
            if Tms::LinkedSetAcq.used?
              base << :linked_set_acq__prep
            end
            if Tms::LotNumAcq.used?
              base << :lot_num_acq__prep
            end
            if Tms::OneToOneAcq.used?
              base << :one_to_one_acq__prep
            end
            base
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[acquisitionreferencenumber increment]
              transform Tms::Transforms::IdGenerator,
                id_source: :acquisitionreferencenumber,
                id_target: :acquisitionreferencenumber,
                separator: " uniq "
            end
          end
        end
      end
    end
  end
end
