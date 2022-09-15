# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module CompiledDataRaw
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :names__initial_compile
              },
              transformer: xforms
            )
          end

          def sources
            base = %i[
                      names__from_constituents
                      names__from_constituents_orgs_from_persons
                      names__from_constituents_persons_from_orgs
                     ]
            base << :names__from_loans if Tms::Loans.used?
            base << :names__from_obj_accession if Tms::ObjAccession.used?
            base << :names__from_obj_locations if Tms::ObjLocations.used?
            if Tms::AssocParents.used? && Tms::AssocParents.target_tables.any?('Constituents')
              base << :names__from_assoc_parents_for_con
            end
            base << :names__from_loc_approvers if Tms::LocApprovers.used?
            base << :names__from_loc_handlers if Tms::LocHandlers.used?
            base << :names__from_obj_incoming if Tms::ObjIncoming.used?
            base
          end

          def xforms
            Kiba.job_segment do
              @deduper = {}

              transform Fingerprint::Add,
                fields: Tms::Services::FingerprintFields.names,
                delim: '␟', # Unicode Character 'SYMBOL FOR UNIT SEPARATOR' (U+241F)
                target: :fingerprint,
                override_app_delim_check: false
              transform Deduplicate::Flag, on_field: :norm, in_field: :duplicate, using: @deduper,
                explicit_no: false
              transform Append::NilFields, fields: Tms::Names.compilation.multi_source_normalizer.get_fields
              transform Append::NilFields, fields: %i[migration_action approx_normalized]
            end
          end
        end
      end
    end
  end
end
