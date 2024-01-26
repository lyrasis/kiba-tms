# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module UserFields
        module Used
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__user_field_xrefs,
                destination: :user_fields__used
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: :userfieldid
              transform Deduplicate::Table,
                field: :userfieldid
            end
          end
        end
      end
    end
  end
end
