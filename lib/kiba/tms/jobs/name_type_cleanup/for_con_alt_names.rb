# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module ForConAltNames
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_type_cleanup__returned_prep,
                destination: :name_type_cleanup__for_con_alt_names
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldMatchRegexp,
                action: :keep,
                field: :termsource,
                match: '^TMS ConAltNames'

              # extract altnameid
              transform do |row|
                row[:altnameid] = row[:constituentid].split('.')
                  .first
                row
              end

              transform Delete::Fields,
                fields: %i[termsource constituentid]
            end
          end
        end
      end
    end
  end
end
