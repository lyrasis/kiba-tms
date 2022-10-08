# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module ForConOrgWithNameParts
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_type_cleanup__returned_prep,
                destination: :name_type_cleanup__for_con_org_with_name_parts
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :termsource,
                value: 'TMS Constituents.orgs_name_detail'
              transform Delete::Fields, fields: :termsource
            end
          end
        end
      end
    end
  end
end
