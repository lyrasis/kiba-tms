# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        module Shape
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :objects__external_data_merged,
                destination: :objects__shape
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              custom_handled_fields = config.custom_map_fields

              unless config.transformer_fields.empty?
                xforms = config.transformer_fields
                  .map { |field| "#{field}_xform".to_sym }
                  .map { |setting| config.send(setting) }
                  .compact
                transform do |row|
                  xforms.each do |xform|
                    row = xform.process(row)
                  end
                  row
                end
              end

              rename_map = {
                chat: :viewerscontributionnote,
                culture: :objectproductionpeople,
                description: :briefdescription,
                medium: :materialtechniquedescription,
                notes: :comment,
                objectcount: :numberofobjects
              }
              unless bind.receiver.send(:merges_dimensions?)
                unless Tms::Dimensions.migrate_secondary_unit_vals
                  transform do |row|
                    display = row[:dimensions]
                    row[:dimensions] = display.sub(/ \(.*\)$/, "")
                    row
                  end
                end
                rename_map[:dimensions] = :dimensionsummary
              end
              custom_handled_fields.each { |field| rename_map.delete(field) }
              transform Rename::Fields,
                fieldmap: rename_map.merge(Tms::Objects.custom_rename_fieldmap)

              transform Delete::DelimiterOnlyFieldValues,
                fields: %w[contentnote objectproductionnote
                  objecthistorynote].map { |prefix|
                          config.send("#{prefix}_sources".to_sym)
                        }.flatten,
                delim: Tms.delim,
                treat_as_null: Tms.nullvalue

              %w[annotation nontext_inscription text_inscription].each do |type|
                sources = config.send("#{type}_source_fields".to_sym)
                targets = config.send("#{type}_target_fields".to_sym)
                if !sources.empty? && !targets.empty?
                  transform Collapse::FieldsToRepeatableFieldGroup,
                    sources: sources,
                    targets: targets,
                    delim: Tms.delim
                end
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: Tms::Objects.comment_fields,
                target: :comment,
                delim: Tms.delim,
                delete_sources: true

              unless Tms::Objects.named_coll_fields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: Tms::Objects.named_coll_fields,
                  target: :namedcollection,
                  delim: Tms.delim,
                  delete_sources: true
              end

              %w[
                contentnote objectproductionnote
                objecthistorynote
              ].each do |target|
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.send("#{target}_sources".to_sym),
                  target: target,
                  delim: config.send("#{target}_delim".to_sym),
                  delete_sources: true
              end
            end
          end
        end
      end
    end
  end
end
