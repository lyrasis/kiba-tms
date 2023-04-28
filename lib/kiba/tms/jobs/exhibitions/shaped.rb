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

          def publishto_true_value
            Tms.using_public_browser ? 'CollectionSpace Public Browser' : 'None'
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

              # Move locationname/auth to Gallery rotation if there is a
              #   venue_xref
              transform do |row|
                row[:galleryrotationname] = nil
                venue = row[:venue_xref_org]
                next row if venue.blank?

                row[:galleryrotationname] = row[:locationname]
                row[:locationauth] = nil
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

              transform Rename::Fields, fieldmap: {
                venue_xref_org: :venueorganizationlocal,
                venue_xref_open_date: :venueopeningdate,
                venue_xref_close_date: :venueclosingdate,
                publicinfo: :publishto
              }

              transform Append::ToFieldValue,
                field: :department, value: ' department'
              transform Merge::ConstantValueConditional,
                fieldmap: { dept_exhibitionpersonrole: 'Responsible department'},
                condition: ->(row){ !row[:department].blank? }
              transform Rename::Field,
                from: :department,
                to: :dept_exhibitionpersonorganizationlocal
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[
                            exhibitionpersonorganizationlocal
                            dept_exhibitionpersonorganizationlocal
                           ],
                target: :exhibitionpersonorganizationlocal,
                sep: Tms.sgdelim,
                delete_sources: true

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[
                            exhibitionpersonpersonlocalrole
                            exhibitionpersonorganizationlocalrole
                            dept_exhibitionpersonrole
                           ],
                target: :exhibitionpersonrole,
                sep: Tms.sgdelim,
                delete_sources: true

              %i[boilerplatetext curatorialnote generalnote
                 planningnote].each do |field|
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.send("#{field}_sources".to_sym),
                  target: field,
                  sep: '%CR%',
                  delete_sources: true
              end

              {
                exhtravelling: {'0'=>nil, '1'=>'traveling'},
                publishto: {'0'=>'None', '1'=>job.send(:publishto_true_value)},
                isinhouse: {'0'=>nil, '1'=>'in-house'},
                isvirtual: {'0'=>nil, '1'=>'virtual'}
              }.each do |field, mapping|
                transform Replace::FieldValueWithStaticMapping,
                  source: field,
                  mapping: mapping
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[isinhouse exhtravelling isvirtual],
                target: :type,
                sep: ' + ',
                delete_sources: true

              transform Delete::EmptyFields
            end
          end
        end
      end
    end
  end
end
