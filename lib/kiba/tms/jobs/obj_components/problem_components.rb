# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module ProblemComponents
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_components__with_object_numbers_by_compid,
                destination: :obj_components__problem_components
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :problemcomponent
              transform Delete::Fields,
                fields: %i[is_top_object problemcomponent existingobject
                  objectid]
            end
          end
        end
      end
    end
  end
end
