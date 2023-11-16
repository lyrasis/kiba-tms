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
              rename_map = config.rename_map

              transform Tms::Transforms::Objects::FieldXforms

              # This needs to be done before Rename::Fields
              unless config.dimensions_to_merge?
                unless Tms::Dimensions.migrate_secondary_unit_vals
                  transform(
                    Tms::Transforms::Dimensions::DeleteSecondaryUnitVals,
                    field: :dimensions
                  )
                end
              end

              transform Rename::Fields, fieldmap: rename_map

              if Tms::Departments.used? && config.department_coll_prefix
                transform Prepend::ToFieldValue,
                  field: :department,
                  value: config.department_coll_prefix
              end

              if config.objectname_shape_xform
                transform config.objectname_shape_xform
              end

              unless config.cataloged_shape_xforms.empty?
                transform Tms::Transforms::List,
                  xforms: config.cataloged_shape_xforms
              end

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
                  target: :namedcollection_raw,
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

              unless config.post_shape_xforms.empty?
                transform Tms::Transforms::List,
                  xforms: config.post_shape_xforms
              end
            end
          end
        end
      end
    end
  end
end
