# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjGeography
        module AuthUniqueOrig
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_geography__for_authority,
                destination: :obj_geography__auth_unique_orig
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
             # Add count of content fields populated per row
             getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
               fields: config.content_fields
             )
             transform do |row|
               vals = getter.call(row)
               row[:popfieldct] = vals.length
               row
             end
            end
          end
        end
      end
    end
  end
end
