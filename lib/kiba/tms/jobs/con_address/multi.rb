# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAddress
        module Multi
          module_function
          
          def job
            Tms.config.constituents.address_active = true
            Tms.config.constituents.address_remarks_handling = :plain
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :con_address__to_merge,
                destination: :con_address__multi,
                lookup: :con_address__add_counts
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: con_address__add_counts,
                keycolumn: :constituentid,
                fieldmap: {
                  person: :person,
                  org: :org,
                  termdisplayname: Tms::Constituents.preferred_name_field,
                  addresscount: :addresscount
                }

              transform do |row|
                person = row[:person]
                org = row[:org]
                val = 'person' unless person.blank?
                val = 'organization' unless org.blank?
                row[:type] = val
                row
              end

              transform Delete::Fields, fields: %i[person org constituentid displayaddress shortname]
            end
          end
        end
      end
    end
  end
end
