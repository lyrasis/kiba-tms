# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LocsClean
        module OrgLookup
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :locclean__organization,
                destination: :locclean__org_lookup,
                lookup: :orgs__by_norm
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: %i[location_name address fulllocid]
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID, source: :location_name, target: :norm
              transform Merge::MultiRowLookup,
                lookup: orgs__by_norm,
                keycolumn: :norm,
                fieldmap: { org: Tms::Constituents.preferred_name_field }
              transform do |row|
                org = row[:org]
                if org.blank?
                  row[:termdisplayname] = row[:location_name]
                  row[:new_org] = 'y'
                else
                  row[:termdisplayname] = row[:org]
                  row[:new_org] = nil
                end
                row
              end
              transform Delete::Fields, fields: %i[org norm location_name]
            end
          end
        end
      end
    end
  end
end
