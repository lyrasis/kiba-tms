# frozen_string_literal: true

module Kiba
  module Tms
    module ObjectLevels
      extend self
      
      def prep
        Kiba::Extend::Jobs::Job.new(
          files: {
            source: :tms__object_levels,
            destination: :prep__object_levels
          },
          transformer: prep_xforms
        )
      end

      def prep_xforms
        Kiba.job_segment do
          transform Tms::Transforms::DeleteTmsFields
          transform FilterRows::FieldMatchRegexp,
            action: :reject,
            field: :objectlevel,
            match: '^(\(|\[)[Nn]ot [Dd]efined(\)|\])$'
        end
      end
    end
  end
end
