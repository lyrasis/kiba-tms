# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module ByConstituentid
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__prep_clean,
                destination: :names__by_constituentid
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              prefname = Tms::Constituents.preferred_name_field
              nonprefname = Tms::Constituents.var_name_field
              default = Tms::Constituents.untyped_default
              default_target = default == 'Person' ? :person : :org

              transform Append::NilFields,
                fields: %i[person org prefname nonprefname]
              transform do |row|
                contype = row[:contype]
                name = row[prefname]
                row[:prefname] = name
                row[:nonprefname] = row[nonprefname]

                if contype.blank?
                  row[default_target] = name
                elsif contype.start_with?('Person')
                  row[:person] = name
                elsif contype.start_with?('Org')
                  row[:org] = name
                else
                  row[default_target] = name
                end
                row
              end
              transform Delete::FieldsExcept,
                fields: %i[constituentid person org prefname nonprefname]
            end
          end
        end
      end
    end
  end
end
