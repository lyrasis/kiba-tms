# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjGeography
        module ForCleanup
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_geography,
                destination: :obj_geography__for_cleanup
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

             transform Delete::Fields,
               fields: config.non_content_fields
             transform Deduplicate::Table,
               field: :combined,
               delete_field: true
             transform Tms::Transforms::ObjGeography::ExplodeValues
             transform Sort::ByFieldValue,
               field: :value,
               mode: :string
            end
          end
        end
      end
    end
  end
end
