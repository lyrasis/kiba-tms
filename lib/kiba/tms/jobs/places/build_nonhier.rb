# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module BuildNonhier
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__cleaned_unique,
                destination: :places__build_nonhier
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::Fields,
                fields: [config.worksheet_added_fields, :notes].flatten
              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: config.non_hierarchy_fields
              transform Delete::FieldsExcept,
                fields: [config.non_hierarchy_fields, :norm_combineds].flatten
              transform Clean::StripFields,
                fields: :all
              if config.qualify_non_hierarchical_terms
                config.non_hierarchy_fields.each do |field|
                  transform Append::ToFieldValue,
                    field: field,
                    value: "///#{config.nonhier_qualifier_prefix}#{field}"
                end
              end
              transform CombineValues::FromFieldsWithDelimiter,
                sources: config.non_hierarchy_fields,
                target: :place,
                delim: Tms.delim
              transform Explode::RowsFromMultivalField,
                field: :place
              transform Sort::ByFieldValue,
                field: :place,
                mode: :string
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: :place,
                target: :norm
              transform Replace::NormWithMostFrequentlyUsedForm,
                normfield: :norm,
                nonnormfield: :place
            end
          end
        end
      end
    end
  end
end
