# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module ProblemComponentLmi
          module_function

          def job
            return unless config.used?

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
                fieldmap: {
                  problem: :componentnumber,
                  parent_object: :parentobjectnumber
                }
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :problem
              transform Delete::Fields, fields: :problem
            end
          end

          def finalize
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::EmptyFields
              transform Delete::Fields,
                fields: %i[objlocationid componentid homelocationid fingerprint
                  prevobjlocid nextobjlocid fullhomelocid]
            end
          end
        end
      end
    end
  end
end
