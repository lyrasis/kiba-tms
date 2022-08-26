# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromConPersonPlain
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :constituents__for_compile,
                destination: :name_compile__from_con_person_plain
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile::multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  type = row[:contype]
                  type && type.start_with?('Person')
                end
              transform Delete::Fields, fields: Tms::NameCompile.person_nil
              transform Merge::ConstantValues,
                constantmap: {
                  relation_type: '_main term',
                  termsource: 'TMS Constituents.persons'
                }
            end
          end
        end
      end
    end
  end
end
