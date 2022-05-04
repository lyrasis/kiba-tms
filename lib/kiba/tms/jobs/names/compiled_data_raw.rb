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
                source: %i[names__from_constituents names__from_constituents_orgs_from_persons
                           names__from_constituents_persons_from_orgs names__from_loans
                           names__from_obj_accession names__from_obj_locations],
                destination: :names__initial_compile
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              @deduper = {}

              transform Fingerprint::Add,
                fields: Tms::Services::FingerprintFields.names,
                delim: '|||',
                target: :fingerprint,
                override_app_delim_check: true
              transform Deduplicate::Flag, on_field: :norm, in_field: :duplicate, using: @deduper,
                explicit_no: false
              transform Append::NilFields, fields: Tms.name_compilation.multi_source_normalizer.get_fields
              transform Append::NilFields, fields: %i[migration_action approx_normalized]
            end
          end
        end
      end
    end
  end
end
