# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TextEntries
        module ForReferenceMaster
          module_function

          def job
            return unless Tms::TextEntries.target_tables.any?('ReferenceMaster')
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__text_entries,
                destination: :text_entries__for_reference_master
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :tablename, value: 'ReferenceMaster'
              transform Delete::Fields, fields: %i[tableid table]
              
              if Tms::TextEntries.for_reference_master_transform
                transform Tms::TextEntries.for_reference_master_transform
              end
            end
          end
        end
      end
    end
  end
end
