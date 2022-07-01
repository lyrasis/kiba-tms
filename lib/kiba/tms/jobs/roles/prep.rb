# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Roles
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__roles,
                destination: :prep__roles,
                lookup: :prep__role_types
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :role
              transform Delete::Fields, fields: %i[anonymousnameid prepositional]

              transform Merge::MultiRowLookup,
                lookup: prep__role_types,
                keycolumn: :roletypeid,
                fieldmap: {roletype: :roletype}
              transform Delete::Fields, fields: :roletypeid
            end
          end
        end
      end
    end
  end
end
