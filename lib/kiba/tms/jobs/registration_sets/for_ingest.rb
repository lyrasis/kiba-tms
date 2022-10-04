# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module RegistrationSets
        module ForIngest
          module_function

          def job
            return unless config.used?
            return unless Tms::ObjAccession.processing_approaches.any?(
              :linkedlot
            )
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__registration_sets,
                destination: :registration_sets__for_ingest
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields, fields: :registrationsetid
            end
          end
        end
      end
    end
  end
end
