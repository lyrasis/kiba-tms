# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      class AbstractPrep
        def initialize(filekey)
          @key = filekey
        end
        
        def prep
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: "tms__#{key}".to_sym,
              destination: "prep__#{key}".to_sym
            },
            transformer: prep_xforms
          )
        end

        def prep_xforms
          Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform Delete::EmptyFields
          end
        end

        private

        attr_reader :key
      end
    end
  end
end
