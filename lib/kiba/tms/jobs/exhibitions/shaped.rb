# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Exhibitions
        module Shaped
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__exhibitions,
                destination: :exhibitions__shaped
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[exhtitle subtitle],
                target: :title,
                sep: ': ',
                delete_sources: true

              # Remove locationname/auth if there is a venue_xref
              transform do |row|
                venue = row[:venue_xref_org]
                next row if venue.blank?

                %i[locationname locationauth].each do |field|
                  row[field] = nil
                end
                row
              end

              # Move general/exhibition dates to venue_xref dates if
              #  no venue specific dates were merged in
              {beginisodate: :venue_xref_open_date,
               endisodate: :venue_xref_close_date}.each do |exh, ven|
                transform do |row|
                  general = row[exh]
                  next row if general.blank?

                  venue = row[ven]
                  row[ven] = general if venue.blank?
                  row[exh] = nil
                  row
                end
              end
              transform Delete::EmptyFields

              transform Rename::Fields, fieldmap: {
                planningnotes: :planningnote,
                curnotes: :curatorialnote,
                remarks: :generalnote,
                insindnote: :boilerplatetext,
                venue_xref_org: :venueorganizationlocal,
                venue_xref_open_date: :venueopeningdate,
                venue_xref_close_date: :venueclosingdate,
                publicinfo: :publishto
              }

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[
                            exhibitionpersonpersonlocalrole
                            exhibitionpersonorganizationlocalrole
                           ],
                target: :exhibitionpersonrole,
                sep: Tms.delim,
                delete_sources: true

              {
                exhtravelling: {'0'=>nil, '1'=>'traveling'},
                publishto: {'0'=>'None', '1'=>'CollectionSpace Public Browser'},
                isinhouse: {'0'=>nil, '1'=>'in-house'},
                isvirtual: {'0'=>nil, '1'=>'virtual'}
              }.each do |field, mapping|
                transform Replace::FieldValueWithStaticMapping,
                  source: field,
                  mapping: mapping
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[isinhouse exhtravelling isvirtual],
                target: :exhibitiontype,
                sep: ' + ',
                delete_sources: true

            end
          end
        end
      end
    end
  end
end
