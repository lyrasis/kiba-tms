# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAltNames
        extend self
        
        def prep
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__con_alt_names,
              destination: :prep__con_alt_names
            },
            transformer: prep_xforms
          )
        end

        def prep_xforms
          Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
          end
        end
      end
    end
  end
end
