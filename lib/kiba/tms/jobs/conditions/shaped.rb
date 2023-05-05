# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Conditions
        module Shaped
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__conditions,
                destination: :conditions__shaped
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Rename::Fields,
                fieldmap: config.rename_fieldmap

              config.prepend_label_map.each do |field, val|
                transform Prepend::ToFieldValue, field: field, value: val
              end

              # Copy :conditioncheckassessmentdate to :conditiondate if
              #   :condition is populated
              transform do |row|
                condition = row[:primary_condition]
                if condition.blank?
                  row[:primary_conditiondate] = nil
                else
                  row[:primary_conditiondate] =
                    row[:conditioncheckassessmentdate]
                end
                row
              end

              if Tms::CondLineItems.used?
                config.cond_line_mergers.each do |merger|
                  transform merger
                end
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: config.conditionchecknote_sources,
                target: :conditionchecknote,
                delim: "%CR%",
                delete_sources: true

              transform Collapse::FieldsToRepeatableFieldGroup,
                sources: config.condition_field_group_sources,
                targets: config.condition_field_group_targets,
                delim: Tms.delim

              transform Delete::Fields, fields: :condlineitem_ct
            end
          end
        end
      end
    end
  end
end
