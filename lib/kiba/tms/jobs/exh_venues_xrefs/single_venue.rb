# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhVenuesXrefs
        module SingleVenue
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__exh_venues_xrefs,
                destination: :exh_venues_xrefs__single_venue
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              transform Delete::Fields,
                fields: %i[beginisodate endisodate displayorder exhibitionnumber
                  exhtitle venueorg thevenue]
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :venuecount,
                value: "single"
              transform Delete::Fields,
                fields: :venuecount
              transform Delete::EmptyFields

              config.boolean_fields_mapping.each do |field, prefix|
                transform Replace::FieldValueWithStaticMapping,
                  source: field,
                  target: "#{field}_exhibitionstatusnote".to_sym,
                  mapping: Tms.boolean_yes_no_mapping,
                  delete_source: true
                transform Merge::ConstantValue,
                  target: "#{field}_exhibitionstatus".to_sym,
                  value: prefix
              end
              transform Collapse::FieldsToRepeatableFieldGroup,
                sources: config.boolean_fields_mapping.keys,
                targets: %i[exhibitionstatus exhibitionstatusnote],
                delim: Tms.delim

              transform Rename::Field,
                from: :insind,
                to: :insindnote
              transform CombineValues::FromFieldsWithDelimiter,
                sources: config.insurancenote_sources,
                target: :insurancenote,
                delim: "%CR%"

              config.field_prefixes.each do |field, prefix|
                transform Prepend::ToFieldValue,
                  field: field,
                  value: "#{prefix}: "
              end

              %w[planningnote curatorialnote generalnote
                boilerplatetext].each do |field|
                sources = config.send("#{field}_sources".to_sym)
                next if sources.empty?

                transform CombineValues::FromFieldsWithDelimiter,
                  sources: sources,
                  target: field,
                  delim: Tms.notedelim
              end

              transform Merge::ConstantValueConditional,
                fieldmap: {venuepersonrole: "Venue"},
                condition: ->(row) do
                  !row[:venueperson].blank?
                end
              transform Clean::RegexpFindReplaceFieldVals,
                fields: %i[otherperson otherpersonrole],
                find: /\|/,
                replace: "^^"
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[venueperson otherperson],
                target: :exhibitionpersonpersonlocal,
                delim: "^^"
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[venuepersonrole otherpersonrole],
                target: :exhibitionpersonrole,
                delim: "^^"
            end
          end
        end
      end
    end
  end
end
