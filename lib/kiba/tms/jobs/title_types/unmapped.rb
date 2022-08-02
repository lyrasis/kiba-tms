# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TitleTypes
        module Unmapped
          module_function
          
          def job
            return unless Tms::Table::List.include?('TitleTypes')
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__title_types,
                destination: :title_types__unmapped
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :titletype, value: 'UNMAPPED'
            end
          end
        end
      end
    end
  end
end
