# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LocsClean
        module Splitter
          module_function

          ITERATION = Tms::Locations.cleanup_iteration

          def job(type:)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: "locclean#{ITERATION}__prep".to_sym,
                destination: "locclean__#{type}".to_sym
              },
              transformer: xforms(type)
            )
          end

          def xforms(type)
            Kiba.job_segment do
              match_type = type.to_s.capitalize
              transform FilterRows::FieldEqualTo, action: :keep, field: :storage_location_authority, value: match_type
              transform Delete::Fields, fields: :storage_location_authority
            end
          end
        end
      end
    end
  end
end
