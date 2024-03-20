# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhVenuesXrefs
        module MultiVenue
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__exh_venues_xrefs,
                destination: :exh_venues_xrefs__multi_venue
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
                  exhtitle venueorg]

              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :venuecount,
                value: "multi"
              transform Delete::Fields,
                fields: :venuecount
              transform Delete::EmptyFields

              transform Copy::Field,
                from: :thevenue,
                to: :venueinparens
              transform Prepend::ToFieldValue,
                field: :venueinparens,
                value: "("
              transform Append::ToFieldValue,
                field: :venueinparens,
                value: ")"

              config.boolean_fields_mapping.each do |field, prefix|
                notefield = "#{field}_exhibitionstatusnote".to_sym
                transform Replace::FieldValueWithStaticMapping,
                  source: field,
                  target: notefield,
                  mapping: Tms.boolean_yes_no_mapping,
                  delete_source: true
                transform do |row|
                  val = row[notefield]
                  row[notefield] = "#{val} #{row[:venueinparens]}"
                  row
                end
                transform Merge::ConstantValue,
                  target: "#{field}_exhibitionstatus".to_sym,
                  value: prefix
              end
              transform Collapse::FieldsToRepeatableFieldGroup,
                sources: config.boolean_fields_mapping.keys,
                targets: %i[exhibitionstatus exhibitionstatusnote],
                delim: Tms.delim

              config.field_prefixes.each do |field, prefix|
                prevalfield = "#{field}preval".to_sym
                transform Merge::ConstantValueConditional,
                  fieldmap: {prevalfield => prefix},
                  condition: ->(row) do
                    !row[field].blank?
                  end
                prefield = "#{field}pre".to_sym
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: [prevalfield, :venueinparens],
                  target: prefield,
                  delete_sources: false,
                  delim: " "
                transform Prepend::FieldToFieldValue,
                  target_field: field,
                  prepended_field: prefield,
                  sep: ": "
                transform Delete::Fields, fields: [prevalfield, prefield]
              end

              %i[planningnote curatorialnote generalnote
                boilerplatetext].each do |field|
                sources = config.send("#{field}_sources".to_sym)
                next if sources.empty?

                transform CombineValues::FromFieldsWithDelimiter,
                  sources: sources,
                  target: field,
                  delim: Tms.notedelim
              end

              transform do |row|
                row[:workinggrouptitle] = nil
                roles = row[:otherpersonrole]
                next row if roles.blank?

                row[:workinggrouptitle] = row[:thevenue]
                row
              end
              transform Clean::RegexpFindReplaceFieldVals,
                fields: %i[otherperson otherpersonrole],
                find: /\|/,
                replace: "^^"
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[otherperson],
                target: :exhibitionpersonpersonlocal,
                delim: "^^"
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[otherpersonrole],
                target: :exhibitionpersonrole,
                delim: "^^"
              transform Delete::Fields,
                fields: %i[thevenue venueinparens]
            end
          end
        end
      end
    end
  end
end
