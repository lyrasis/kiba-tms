# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module ProblemComponents
          module_function

          def job
            return unless config.used?
            return unless config.actual_components

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_components__with_object_numbers_by_compid,
                destination: :obj_components__problem_components,
                lookup: %i[
                            locs__compiled_clean
                            tms__obj_locations
                           ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :problemcomponent
              transform Merge::MultiRowLookup,
                lookup: tms__obj_locations,
                keycolumn: :currentobjlocid,
                fieldmap: {
                  currentlocationid: :locationid
                }
              transform Delete::Fields,
                fields: :currentobjlocid
              %i[homelocationid currentlocationid].each do |id|
                target = id.to_s.delete_suffix("id").to_sym
              transform Append::ToFieldValue,
                field: id,
                value: '|nil'
              transform Merge::MultiRowLookup,
                lookup: locs__compiled_clean,
                keycolumn: id,
                fieldmap: {
                  target=>:location_name
                }
              transform Delete::Fields, fields: id
              end
            end
          end
        end
      end
    end
  end
end
