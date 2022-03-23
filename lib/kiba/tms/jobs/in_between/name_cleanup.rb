# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module InBetween
        # Namespace for jobs that deal with merging client name cleanup back into migration
        module NameCleanup
          module_function
          def unfingerprinted
            xforms = Kiba.job_segment do
              # fields added to support client work
              transform Delete::Fields,
                fields: %i[approx_normalized duplicate inconsistent_org_names missing_last_name
                           matchpref orig_pref_name]
              transform Rename::Field, from: :preferred_name_form, to: Tms.constituents.preferred_name_field
              transform Rename::Field, from: :variant_name_form, to: Tms.constituents.alt_name_field
              transform Fingerprint::Decode,
                fingerprint: :fingerprint,
                source_fields: Tms::Services::FingerprintFields.names,
                delim: '|||',
                prefix: 'fp'              
            end

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :names__cleaned_zero,
                destination: :name_cleanup__unfingerprinted
              },
              transformer: xforms
            )
          end
        end
      end
    end
  end
end
