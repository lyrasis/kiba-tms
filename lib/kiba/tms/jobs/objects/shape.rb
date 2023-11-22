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
                source: :objects__merged_data_prep,
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

              # Start section preparing fields for later combination
              if Tms::Departments.used? && config.department_coll_prefix
                transform Prepend::ToFieldValue,
                  field: :department,
                  value: config.department_coll_prefix
              end

              unless config.cataloged_shape_xforms.empty?
                transform Tms::Transforms::List,
                  xforms: config.cataloged_shape_xforms
              end

              case config.catrais_treatment
              when :referencenote
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: {catrais: :catrais_referencenote},
                  constant_target: :catrais_reference,
                  constant_value: "%NULLVALUE%"
              when :delete
                transform Delete::Fields,
                  fields: :catrais
              end

              case config.curatorapproved_treatment
              when :invstatus
                transform Tms::Transforms::Objects::Curatorapproved
              when :delete
                transform Delete::Fields, fields: :curatorapproved
              end

              case config.exhibitions_treatment
              when :usage
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: {exhibitions: :exh_usagenote},
                  constant_target: :exh_usage,
                  constant_value: "exhibition"
              when :delete
                transform Delete::Fields,
                  fields: :exhibitions
              end

              case config.paperfileref_treatment
              when :referencenote
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: {paperfileref: :paper_referencenote},
                  constant_target: :paper_reference,
                  constant_value: "%NULLVALUE%"
              when :delete
                transform Delete::Fields,
                  fields: :paperfileref
              end

              case config.pubreferences_treatment
              when :referencenote
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: {pubreferences: :pubref_referencenote},
                  constant_target: :pubref_reference,
                  constant_value: "%NULLVALUE%"
              when :delete
                transform Delete::Fields,
                  fields: :pubreferences
              end
              # End section preparing fields for later combination

              %w[annotation assocplace material nontext_inscription
                objectname reference text_inscription usage].each do |type|
                sources = config.send("#{type}_source_fields".to_sym)
                targets = config.send("#{type}_target_fields".to_sym)
                if !sources.empty? && !targets.empty?
                  transform Collapse::FieldsToRepeatableFieldGroup,
                    sources: sources,
                    targets: targets,
                    delim: Tms.delim
                end
              end

              %w[comment inventorystatus
                contentconceptconceptassociated].each do |target|
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.send("#{target}_sources".to_sym),
                  target: target.to_sym,
                  delim: Tms.delim,
                  delete_sources: true
              end

              unless Tms::Objects.named_coll_fields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: Tms::Objects.named_coll_fields,
                  target: :namedcollection_raw,
                  delim: Tms.delim,
                  delete_sources: true
              end

              notefields = %w[
                contentnote contentdescription
                objectproductionnote objecthistorynote
              ]
              transform Delete::DelimiterOnlyFieldValues,
                fields: notefields.map { |prefix|
                  config.send("#{prefix}_sources".to_sym)
                }.flatten,
                delim: Tms.delim,
                treat_as_null: Tms.nullvalue

              notefields.each do |target|
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.send("#{target}_sources".to_sym),
                  target: target.to_sym,
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
