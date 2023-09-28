# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjAccession
        module InMigration
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_accession__initial_prep,
                destination: :obj_accession__in_migration
              },
              transformer: xforms
            )
          end

          def dropping_loanins?
            lot = config.loaned_object_treatment
            true if lot == :creditline_to_loanin || lot == :drop
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              if bind.receiver.send(:dropping_loanins?)
                transform FilterRows::FieldEqualTo,
                  action: :reject,
                  field: :loanin,
                  value: "y"
              end
              transform Delete::Fields,
                fields: :loanin
            end
          end
        end
      end
    end
  end
end
