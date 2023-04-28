# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConservationTreatments
        module Cspace
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :conservation_treatments__all,
                destination: :conservation_treatments__cspace
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              csfields = config.cs_fields

              transform do |row|
                row.keys.each do |field|
                  next if csfields.any?(field)

                  row.delete(field)
                end
                row
              end
            end
          end
        end
      end
    end
  end
end
