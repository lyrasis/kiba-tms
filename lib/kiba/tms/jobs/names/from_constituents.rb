# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module FromConstituents
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :constituents__alt_names_merged,
                destination: :names__from_constituents
              },
              transformer: xforms,
              helper: Kiba::Tms.name_compilation.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do              
              transform Delete::Fields, fields: %i[namedata defaultdisplaybioid defaultnameid displaydate]
              unless Kiba::Tms::Constituents.date_append.to_types == [:none]
                transform Kiba::Tms::Transforms::Constituents::AppendDatesToNames
              end
              transform Rename::Field, from: :position, to: :contact_role
              transform Cspace::NormalizeForID,
                source: Tms::Constituents.preferred_name_field,
                target: :norm
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Constituents'
            end
          end
        end
      end
    end
  end
end
