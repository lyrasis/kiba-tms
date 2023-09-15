# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module BuildHierarchical
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__cleaned_unique,
                destination: :places__build_hierarchical
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: config.hierarchy_fields
              transform Delete::FieldsExcept,
                fields: [config.hierarchy_fields, :norm_combineds].flatten
              transform Clean::StripFields,
                fields: :all
              transform CombineValues::FromFieldsWithDelimiter,
                sources: config.hierarchy_fields,
                target: :place,
                delim: config.hierarchy_separator
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
