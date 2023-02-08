# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Nhrs
        module All
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :nhrs__all
              },
              transformer: xforms
            )
          end

          def sources
            %i[
               acquisitions__obj_rels
               exhibitions__nhrs
               loans__nhrs
               obj_deaccession__obj_rel
               obj_locations__nhr_lmi_obj
               valuation_control__nhrs
              ].select{ |job| Tms.job_output?(job) }
          end

          def xforms
            Kiba.job_segment do
              transform CombineValues::FullRecord, target: :index
              transform Deduplicate::Table,
                field: :index,
                delete_field: true
            end
          end
        end
      end
    end
  end
end
