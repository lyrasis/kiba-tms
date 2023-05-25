# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjGeography
        module UniqueNorm
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_geography__unique_orig,
                destination: :obj_geography__unique_norm
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

             transform Delete::Fields,
               fields: config.derived_note_fields
             transform Deduplicate::Table,
               field: :norm_combined,
               delete_field: false
             transform Sort::ByFieldValue,
               field: :norm_combined,
               mode: :string
            end
          end
        end
      end
    end
  end
end
