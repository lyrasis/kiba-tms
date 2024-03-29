# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module RelsAcqObj
        module ForIngest
          module_function

          def job
            return if sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :rels_acq_obj__for_ingest
              },
              transformer: get_xforms
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

          def get_xforms
            return [xforms] unless config.sampleable?

            [config.sample_xforms, xforms]
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::AllFieldsPopulated,
                action: :keep,
                fields: %i[item1_id item2_id]
              transform CombineValues::FullRecord,
                prepend_source_field_name: false,
                delim: " ",
                delete_sources: false

              transform Deduplicate::Table,
                field: :index,
                delete_field: true
            end
          end
        end
      end
    end
  end
end
