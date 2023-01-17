# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module ByNormPrep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__unique,
                destination: :names__by_norm_prep
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
                    'TMS Constituents.orgs',
                    'TMS Constituents.persons',
                    'Uncontrolled'
                  ]
                  rt && rt == '_main term' &&
                    ts && sources.any?(ts) &&
                    !norm.blank?
                end
              transform Delete::FieldsExcept,
                fields: %i[contype name prefnormorig]
              transform Rename::Field,
                from: :prefnormorig,
                to: :norm
              transform Tms::Transforms::Constituents::NormalizeContype,
                target: :contype
              transform Tms::Transforms::Constituents::AddDefaultContype
            end
          end
        end
      end
    end
  end
end
