# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LocsClean
        module Cspace
          module_function

          def job(type:)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: "locclean__#{type}_hier".to_sym,
                destination: "locclean__#{type}_cspace".to_sym
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: %i[current_location_note term_source fulllocid parent_location]
              transform Deduplicate::Table, field: :location_name, delete_field: false
              transform Rename::Field, from: :location_name, to: :termdisplayname
            end
          end
        end
      end
    end
  end
end
