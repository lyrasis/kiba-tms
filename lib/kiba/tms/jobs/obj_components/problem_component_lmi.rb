# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module ProblemComponentLmi
          module_function

          def job
            return unless config.used?
            return unless config.actual_components

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_locations,
                destination: :obj_components__problem_component_lmi,
                lookup: [
                  Tms::Jobs::ObjLocations::Prep.lookups,
                  Tms::Jobs::ObjLocations::LocationNamesMerged.lookups
                  ].flatten
              },
              transformer: [
                keep_problem_component_locs,
                Tms::Jobs::ObjLocations::Prep.xforms,
                Tms::Jobs::ObjLocations::LocationNamesMerged.xforms,
                finalize
              ]
            )
          end

          def keep_problem_component_locs
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: obj_components__problem_components,
                keycolumn: :componentid,
                fieldmap: {problem: :componentnumber}
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :problem
              transform Delete::Fields, fields: :problem
            end
          end

          def finalize
            Kiba.job_segment do
              transform Delete::EmptyFields
              transform Delete::Fields,
                fields: %i[homelocationid fingerprint]
            end
          end
        end
      end
    end
  end
end
