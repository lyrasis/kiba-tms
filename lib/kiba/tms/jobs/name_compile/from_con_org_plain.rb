# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromConOrgPlain
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :constituents__for_compile,
                destination: :name_compile__from_con_org_plain
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  type = row[:contype]
                  type && type.start_with?('Organization')
                end
              transform Delete::Fields, fields: Tms::NameCompile.org_nil
              transform Merge::ConstantValues,
                constantmap: {
                  relation_type: '_main term',
                  termsource: 'TMS Constituents.orgs'
                }
            end
          end
        end
      end
    end
  end
end
