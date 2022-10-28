# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Acquisitions
        module ObjRels
          module_function

          def job
            return if sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :acquisitions__obj_rels
              },
              transformer: xforms
            )
          end

          def sources
            base = []
            if Tms::LinkedSetAcq.used?
              base << :linked_set_acq__acq_obj_rel
            end
            if Tms::LotNumAcq.used?
              base << :lot_num_acq__acq_obj_rel
            end
            base
          end

          def xforms
            Kiba.job_segment do
            end
          end
        end
      end
    end
  end
end
