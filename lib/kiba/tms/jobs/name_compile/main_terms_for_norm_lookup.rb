# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module MainTermsForNormLookup
          module_function

          def job
            return unless Tms::NameCompile.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__unique,
                destination: :name_compile__main_terms_for_norm_lookup
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  rt = row[:relation_type]
                  norm = row[:prefnormorig]
                  ts = row[:termsource]
                  sources = [
                    "TMS Constituents.orgs",
                    "TMS Constituents.persons",
                    "Uncontrolled"
                  ]
                  rt && rt == "_main term" &&
                    ts && sources.any?(ts) &&
                    !norm.blank?
                end
              transform Delete::FieldsExcept,
                fields: %i[name prefnormorig contype]
            end
          end
        end
      end
    end
  end
end
