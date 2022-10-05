# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjAccession
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_accession,
                destination: :prep__obj_accession,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if Tms::AccessionMethods.used? &&
                config.fields.any?(Tms::AccessionMethods.id_field)
              base << :prep__accession_methods
            end
            if Tms::Currencies.used? &&
                config.fields.any?(Tms::Currencies.id_field)
              base << :prep__currencies
            end
            if Tms::ConRefs.for?('ObjAccession')
              base << :con_refs_for__obj_accession
            end
            base
          end

          def xforms
            bind =  binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              accmeth = Tms::AccessionMethods
              curr = Tms::Currencies

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :objectid,
                value: '-1'

              if accmeth.used? && config.fields.any?(accmeth.id_field)
                transform Merge::MultiRowLookup,
                  lookup: prep__accession_methods,
                  keycolumn: accmeth.id_field,
                  fieldmap: {accmeth.type_field => accmeth.type_field}
              end
              transform Delete::Fields, fields: accmeth.id_field

              if curr.used? && config.fields.any?(curr.id_field)
                transform Merge::MultiRowLookup,
                  lookup: prep__currencies,
                  keycolumn: curr.id_field,
                  fieldmap: {curr.type_field => curr.type_field}
              end
              transform Delete::Fields, fields: curr.id_field

              if Tms::ConRefs.for?('ObjAccession')
                transform Tms::Transforms::ConRefs::Merger,
                  into: config,
                  keycolumn: :objectid
              end
            end
          end
        end
      end
    end
  end
end
