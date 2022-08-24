# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Persons
        module ByNorm
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: source,
                destination: :persons__by_norm
              },
              transformer: xforms
            )
          end

          def source
            iteration = Tms::Names.cleanup_iteration
            if iteration
              "nameclean#{iteration}__persons_kept".to_sym
            else
              :name_compile__unique
            end
          end
                    
          def xforms
            Kiba.job_segment do
              unless Tms::Names.cleanup_iteration
                pref = Tms::Constituents.preferred_name_field
                
                transform FilterRows::WithLambda,
                  action: :keep,
                  lambda: ->(row){ row[:contype] == 'Person' && row[:relation_type] == '_main term' }
                transform Delete::FieldsExcept, fields: pref
                transform Kiba::Extend::Transforms::Cspace::NormalizeForID, source: pref, target: :norm
              end
            end
          end
        end
      end
    end
  end
end
