# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAddress
        module Multi
          module_function

          def job
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
                  termdisplayname: :cleanedprefname,
                  addresscount: :addresscount
                },
                conditions: ->(_r, rows){
                  rows.reject{ |r| r[:addresscount] == "1" }
                }
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :addresscount

              transform do |row|
                person = row[:person]
                org = row[:org]
                val = "person" unless person.blank?
                val = "organization" unless org.blank?
                row[:type] = val
                row
              end

              transform Delete::Fields,
                fields: %i[person org constituentid displayaddress shortname]
            end
          end
        end
      end
    end
  end
end
