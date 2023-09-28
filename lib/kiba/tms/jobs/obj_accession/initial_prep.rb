# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjAccession
        module InitialPrep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_accession,
                destination: :obj_accession__initial_prep,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[
              objects__numbers_cleaned
              loan_obj_xrefs__loanin_obj_lookup
            ]
            if Tms::AccessionMethods.used? &&
                config.fields.any?(Tms::AccessionMethods.id_field)
              base << :prep__accession_methods
            end
            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              accmeth = Tms::AccessionMethods

              transform Merge::MultiRowLookup,
                lookup: objects__numbers_cleaned,
                keycolumn: :objectid,
                fieldmap: {objectnumber: :objectnumber}

              transform Merge::MultiRowLookup,
                lookup: objects__numbers_cleaned,
                keycolumn: :objectid,
                fieldmap: {creditline: :creditline}

              transform Merge::MultiRowLookup,
                lookup: loan_obj_xrefs__loanin_obj_lookup,
                keycolumn: :objectid,
                fieldmap: {
                  loanin_id: :loanid
                }
              transform Delete::Fields, fields: :loanobj

              if accmeth.used? && config.fields.any?(accmeth.id_field)
                transform Merge::MultiRowLookup,
                  lookup: prep__accession_methods,
                  keycolumn: accmeth.id_field,
                  fieldmap: {accmeth.type_field => accmeth.type_field}
              end
              transform Delete::Fields, fields: accmeth.id_field
            end
          end
        end
      end
    end
  end
end
