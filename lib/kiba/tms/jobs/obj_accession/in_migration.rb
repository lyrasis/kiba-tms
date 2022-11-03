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
                source: :tms__obj_accession,
                destination: :obj_accession__in_migration,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def dropping_loanins?
            lot = config.loaned_object_treatment
            true if lot == :creditline_to_loanin || lot == :drop
          end

          def lookups
            base = []
            if dropping_loanins?
              base << :loan_obj_xrefs__loanin_obj_lookup
            end
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              if bind.receiver.send(:dropping_loanins?)
                transform Merge::MultiRowLookup,
                  lookup: loan_obj_xrefs__loanin_obj_lookup,
                  keycolumn: :objectid,
                  fieldmap: {loanin: :objectid}
                transform FilterRows::FieldPopulated,
                  action: :reject,
                  field: :loanin
                transform Delete::Fields, fields: :loanin
              end
            end
          end
        end
      end
    end
  end
end
