# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Conditions
        module Cspace
          module_function

          def job
            return unless config.used?

          Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :conditions__cspace
              },
              transformer: xforms
            )
          end

          def sources
            base = [:conditions__objects]
            base.select{ |job| Tms.job_output?(job) }
          end

          def xforms
            Kiba.job_segment do
              transform Append::NilFields,
                fields: Tms::Conditions.multisource_normalizer.get_fields

              transform Tms::Transforms::IdGenerator,
                prefix: 'CC',
                id_source: :recordnumber,
                id_target: :conditioncheckrefnumber,
                sort_on: :conditionid,
                sort_type: :i,
                delete_source: false,
                omit_suffix_if_single: false
            end
          end
        end
      end
    end
  end
end
