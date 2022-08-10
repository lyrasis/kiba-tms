# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module CleanDates
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :tms__constituents,
                destination: :constituents__clean_dates
              },
              transformer: xforms,
              helper: Tms::Constituents.dates.multisource_normalizer
            )
          end
          
          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[constituentid displaydate begindateiso enddateiso nationality]

              transform Append::NilFields, fields: :datenote
              # we add this so that data from Constituents gets preferred over ConDates if different
              transform Merge::ConstantValue, target: :condateid, value: '0'
              
              unless Tms::Constituents.displaydate_cleaners.empty?
                Tms::Constituents.displaydate_cleaners.each do |cleaner|
                  transform cleaner
                end
                transform Delete::Fields, fields: %i[displaydate nationality]
                transform FilterRows::AnyFieldsPopulated, action: :keep, fields: %i[begindateiso enddateiso datenote]
                transform Tms::Transforms::Constituents::ReshapeCleanedDates
                transform Merge::ConstantValue, target: :datasource, value: 'Constituents.displaydate_begindateiso_enddateiso'
              end
            end
          end
        end
      end
    end
  end
end
