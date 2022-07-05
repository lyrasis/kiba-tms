# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module StatusFlags
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__status_flags,
                destination: :prep__status_flags,
                lookup: %i[
                           prep__flag_labels
                           ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :onoff, value: '1'
              transform Delete::Fields, fields: :onoff

              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::TmsTableNames

              transform Rename::Fields, fieldmap: {
                objectid: :recordid,
                statusflagid: :sort
              }
              transform Merge::MultiRowLookup,
                lookup: prep__flag_labels,
                keycolumn: :flagid,
                fieldmap: {flaglabel: :flaglabel}
              transform Delete::Fields, fields: :flagid
            end
          end
        end
      end
    end
  end
end
