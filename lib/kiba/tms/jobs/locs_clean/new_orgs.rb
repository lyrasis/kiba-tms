# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LocsClean
        module NewOrgs
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :locclean__org_lookup,
                destination: :locclean__new_orgs
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[termdisplayname address new_org]
              transform FilterRows::FieldPopulated, action: :keep,
                field: :new_org
              transform Delete::Fields, fields: %i[new_org fulllocid]
              transform Rename::Field, from: :address, to: :addressplace1
            end
          end
        end
      end
    end
  end
end
