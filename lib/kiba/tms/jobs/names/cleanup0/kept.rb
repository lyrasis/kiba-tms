# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module Cleanup0
          module Kept
            module_function

            def job
              Kiba::Extend::Jobs::Job.new(
                files: {
                  source: :nameclean0__prep,
                  destination: :nameclean0__kept
                },
                transformer: xforms
              )
            end

            def xforms
              Kiba.job_segment do
                transform Tms::Transforms::Names::Kept
                transform do |row|
                  row.keys.each{ |field| row.delete(field) if field.to_s.start_with?('fp_') }
                  row
                end
                transform Rename::Field, from: Tms.constituents.preferred_name_field, to: :termdisplayname
              end
            end
          end
        end
      end
    end
  end
end
