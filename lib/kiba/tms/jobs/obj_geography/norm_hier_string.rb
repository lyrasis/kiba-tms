# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjGeography
        module NormHierString
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_geography__unique_norm,
                destination: :obj_geography__norm_hier_string
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
                fields: [config.hierarchy_fields, :norm_combined].flatten
              transform CombineValues::FromFieldsWithDelimiter,
               sources: config.hierarchy_fields,
               target: :value,
               delim: " -- "
              transform Sort::ByFieldValue,
                field: :value,
                mode: :string
              transform Merge::ConstantValue,
                target: :fieldname,
                value: 'hierarchy fields'
            end
          end
        end
      end
    end
  end
end
