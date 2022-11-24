# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module OneToOneAcq
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :one_to_one_acq__combined,
                destination: :one_to_one_acq__prep,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            unless config.row_treatment == :separate
              base << :one_to_one_acq__acq_num_lookup
            end
            base
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              if config.row_treatment == :separate
                transform Copy::Field,
                  from: :acqrefnum,
                  to: :acquisitionreferencenumber
              else
                transform Deduplicate::Table,
                  field: :combined,
                  delete_field: false
                transform Merge::MultiRowLookup,
                  lookup: one_to_one_acq__acq_num_lookup,
                  keycolumn: :combined,
                  fieldmap: {acquisitionreferencenumber: :acqrefnum}
              end

              transform Delete::Fields,
                fields: %i[objectnumber acqrefnum combined]
            end
          end
        end
      end
    end
  end
end
