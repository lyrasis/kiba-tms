# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAddress
        module ToMerge
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :con_address__shaped,
                destination: :con_address__to_merge
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :duplicate,
                value: "n"
              transform Delete::Fields,
                fields: %i[duplicate init_addresscountry origcountry
                  remappedcountry remappedcountrycode]
            end
          end
        end
      end
    end
  end
end
