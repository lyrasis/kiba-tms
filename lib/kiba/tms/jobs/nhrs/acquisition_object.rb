# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Nhrs
        module AcquisitionObject
          module_function

          def job
            return if sources.empty?

            config.config.rectype1 = "Acquisitions"
            config.config.rectype2 = "Collectionobjects"
            config.config.sample_from = :rectype1

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :nhrs__acquisition_object
              },
              transformer: config.transformers
            )
          end

          def sources
            base = []
            if Tms::LinkedSetAcq.used?
              base << :linked_set_acq__acq_obj_rel
            end
            if Tms::LinkedLotAcq.used?
              warn("Implement nhrs for LinkedLotAcq")
            end
            if Tms::LotNumAcq.used?
              base << :lot_num_acq__acq_obj_rel
            end
            if Tms::AcqNumAcq.used?
              base << :acq_num_acq__acq_obj_rel
            end
            if Tms::OneToOneAcq.used?
              base << :one_to_one_acq__acq_obj_rel
            end
            base
          end
        end
      end
    end
  end
end
