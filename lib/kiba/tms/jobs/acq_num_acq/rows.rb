# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AcqNumAcq
        module Rows
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :acq_num_acq__obj_rows,
                destination: :acq_num_acq__rows
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end
              transform CombineValues::FullRecord, target: :combined
              transform Deduplicate::Table,
                field: :combined,
                delete_field: false
              transform Tms::Transforms::IdGenerator,
                id_source: :acquisitionnumber,
                id_target: :acquisitionreferencenumber,
                sort_on: :combined,
                separator: '//'
            end
          end
        end
      end
    end
  end
end
