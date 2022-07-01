# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module RoleTypes
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__role_types,
                destination: :prep__role_types
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :roletype
              transform Delete::Fields, fields: %i[defaultroleid primaryroleid allowsanonymousaccess]
            end
          end
        end
      end
    end
  end
end
