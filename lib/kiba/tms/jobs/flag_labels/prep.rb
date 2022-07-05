# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module FlagLabels
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__flag_labels,
                destination: :prep__flag_labels
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: %i[flagid flaglabel]
              transform Rename::Field, from: :flaglabel, to: :origlabel
              transform Replace::FieldValueWithStaticMapping,
                source: :origlabel,
                target: :flaglabel,
                mapping: Tms::FlagLabels.inventory_status_mapping,
                fallback_val: 'NEEDS MAPPING',
                delete_source: false
            end
          end
        end
      end
    end
  end
end
