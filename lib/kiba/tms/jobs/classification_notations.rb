# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ClassificationNotations
        extend self
        
        def prep
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__classification_notations,
              destination: :prep__classification_notations
            },
            transformer: prep_xforms
          )
        end

        def prep_xforms
          Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform Delete::Fields, fields: %i[dateentered sorttype rank]
          end
        end
      end
    end
  end
end

