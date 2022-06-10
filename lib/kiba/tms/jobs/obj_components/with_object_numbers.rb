# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module WithObjectNumbers
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_components,
                destination: :obj_components__with_object_numbers,
                lookup: :tms__objects
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: tms__objects,
                keycolumn: :objectid,
                fieldmap: {
                  objectnumber: :objectnumber,
                },
                delim: Tms.delim
              transform Tms::Transforms::ObjComponents::FlagTopObjects
            end
          end
        end
      end
    end
  end
end
