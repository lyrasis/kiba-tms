# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Acquisitions
        module All
          module_function

          def job
            return if sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :acquisitions__all
              },
              transformer: xforms
            )
          end

          def sources
            base = []
            if Tms::LinkedSetAcq.used?
              base << :acquisitions__from_linked_set
            end
            if Tms::LinkedLotAcq.used?
              warn("TODO: Finish prep job for LinkedLotAcq")
            end
            if Tms::LotNumAcq.used?
              base << :acquisitions__from_lot_num
            end
            if Tms::AcqNumAcq.used?
              base << :acquisitions__from_acq_num
            end
            if Tms::OneToOneAcq.used?
              base << :acquisitions__from_one_to_one
            end
            base
          end

          def xforms
            Kiba.job_segment do
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
