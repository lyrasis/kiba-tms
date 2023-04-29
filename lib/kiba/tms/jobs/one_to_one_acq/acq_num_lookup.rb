# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module OneToOneAcq
        module AcqNumLookup
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :one_to_one_acq__combined,
                destination: :one_to_one_acq__acq_num_lookup
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::FieldsExcept,
                fields: %i[acqrefnum combined]

              unless config.row_treatment == :separate
                transform Deduplicate::Table,
                  field: :combined,
                  delete_field: false
                transform Tms::Transforms::IdGenerator,
                  id_source: :acqrefnum,
                  id_target: :acqrefnum,
                  separator: "//"
              end
            end
          end
        end
      end
    end
  end
end
