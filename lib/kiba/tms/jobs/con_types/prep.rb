# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConTypes
        module Prep
          module_function
          
          def prep
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_types,
                destination: :prep__con_types
              },
              transformer: prep_xforms
            )
          end

          def prep_xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform FilterRows::FieldMatchRegexp,
                action: :reject,
                field: :constituenttype,
                match: '^(\(|\[)[Nn]ot [Ee]ntered(\)|\])$'
            end
          end
        end
      end
    end
  end
end
