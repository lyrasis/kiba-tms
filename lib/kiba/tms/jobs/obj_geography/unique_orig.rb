# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjGeography
        module UniqueOrig
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_geography,
                destination: :obj_geography__unique_orig
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
               field: :orig_combined,
               delete_field: false
             transform Sort::ByFieldValue,
               field: :orig_combined,
               mode: :string
            end
          end
        end
      end
    end
  end
end
