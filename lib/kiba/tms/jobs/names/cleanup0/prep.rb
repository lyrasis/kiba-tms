# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module Cleanup0
          module Prep
            module_function

            def job
              Kiba::Extend::Jobs::Job.new(
                files: {
                  source: :names__cleaned0,
                  destination: :nameclean0__prep
                },
                transformer: xforms
              )
            end

            def xforms
              Kiba.job_segment do
                # fields added to support client work
                transform Delete::Fields,
                  fields: %i[approx_normalized normalized_form duplicate inconsistent_org_names missing_last_name
                             matchpref orig_pref_name]
                transform Rename::Field, from: :preferred_name_form, to: Tms::Constituents.preferred_name_field
                transform Rename::Field, from: :variant_name_form, to: Tms::Constituents.var_name_field
                transform Fingerprint::Decode,
                  fingerprint: :fingerprint,
                  source_fields: Tms::Services::FingerprintFields.names,
                  delim: '|||',
                  prefix: 'fp'

#                transform FilterRows::FieldEqualTo, action: :reject, field: :migration_action, value: 'skip'
                transform Cspace::NormalizeForID,
                  source: Tms::Constituents.preferred_name_field,
                  target: :norm
              end
            end
          end
        end
      end
    end
  end
end
