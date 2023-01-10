# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjAccession
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_accession__in_migration,
                destination: :prep__obj_accession,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[
                      objects__numbers_cleaned
                      names__map_by_norm
                     ]
            if Tms::AccessionMethods.used? &&
                config.fields.any?(Tms::AccessionMethods.id_field)
              base << :prep__accession_methods
            end
            if Tms::Currencies.used? &&
                config.fields.any?(Tms::Currencies.id_field)
              base << :prep__currencies
            end
            if Tms::ConRefs.for?('ObjAccession')
              base << :con_refs_for__obj_accession
            end
            if config.fields.any?(:accessionvalue) &&
                config.fields.any?(:objectvalueid)
              base << :tms__obj_insurance
            end
            base
          end

          def xforms
            bind =  binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              accmeth = Tms::AccessionMethods
              curr = Tms::Currencies

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end
              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :objectid,
                value: '-1'
              transform Tms.data_cleaner if Tms.data_cleaner

              transform Tms::Transforms::DeleteTimestamps,
                fields: config.date_fields
              transform Tms::Transforms::DeleteEmptyMoney,
                fields: %i[accessionvalue]
              transform Delete::FieldValueMatchingRegexp,
                fields: %i[objectvalueid],
                match: '^-1$'

              # removes :accessionvalue if equal to the value in a linked
              #   ObjInsurance (valuation) record
              if config.fields.any?(:accessionvalue) &&
                  config.fields.any?(:objectvalueid)
                transform Merge::MultiRowLookup,
                  lookup: tms__obj_insurance,
                  keycolumn: :objectvalueid,
                  fieldmap: {vc_value: :value}

                transform do |row|
                  av = row[:accessionvalue]
                  next row if av.blank?

                  vc = row[:vc_value]
                  next row if vc.blank?

                  if av == vc
                    row[:accessionvalue] = nil
                  end
                  row
                end
              end

              transform Merge::MultiRowLookup,
                lookup: objects__numbers_cleaned,
                keycolumn: :objectid,
                fieldmap: {objectnumber: :objectnumber}

              transform Merge::MultiRowLookup,
                lookup: objects__numbers_cleaned,
                keycolumn: :objectid,
                fieldmap: {creditline: :creditline}

              if accmeth.used? && config.fields.any?(accmeth.id_field)
                transform Merge::MultiRowLookup,
                  lookup: prep__accession_methods,
                  keycolumn: accmeth.id_field,
                  fieldmap: {accmeth.type_field => accmeth.type_field}
              end
              transform Delete::Fields, fields: accmeth.id_field

              if curr.used? && config.fields.any?(curr.id_field)
                transform Merge::MultiRowLookup,
                  lookup: prep__currencies,
                  keycolumn: curr.id_field,
                  fieldmap: {curr.type_field => curr.type_field}
              end
              transform Delete::Fields, fields: curr.id_field

              if Tms::ConRefs.for?('ObjAccession')
                transform Tms::Transforms::ConRefs::Merger,
                  into: config,
                  keycolumn: :objectid
              end

              if config.fields.any?(:authorizer)
                transform Tms::Transforms::MergeUncontrolledName,
                  field: :authorizer,
                  lookup: names__map_by_norm
              end

              case config.authorizer_org_treatment
              when :drop
                transform Delete::Fields,
                  fields: :authorizer_org
              else
                transform Prepend::ToFieldValue,
                  field: :authorizer_org,
                  value: config.authorizer_org_prefix
              end

              case config.authorizer_note_treatment
              when :drop
                transform Delete::Fields,
                  fields: :authorizer_note
              else
                transform Prepend::ToFieldValue,
                  field: :authorizer_note,
                  value: config.authorizer_note_prefix
              end

              transform Tms::Transforms::ObjAccession::AuthDateSetter

              if config.fields.any?{ |f| f.to_s.start_with?('approvaliso') }
                case config.approval_date_treatment
                when :drop
                  transform Delete::Fields,
                    fields: %i[approvalisodate1 approvalisodate2]
                else
                  if config.approval_date_note_format == :combined
                    transform CombineValues::FromFieldsWithDelimiter,
                      sources: %i[approvalisodate1 approvalisodate2],
                      target: :approvaldate_note,
                      sep: ", ",
                      delete_sources: true
                    transform Prepend::ToFieldValue,
                      field: :approvaldate_note,
                      value: config.approval_date_combined_prefix
                  else
                    transform Prepend::ToFieldValue,
                      field: :approvalisodate1,
                      value: config.approval_date_1_prefix
                    transform Prepend::ToFieldValue,
                      field: :approvalisodate2,
                      value: config.approval_date_2_prefix
                  end
                end
              end

              if config.initiation_treatment == :drop
                transform Delete::Fields,
                  fields: %i[initiator initdate]
              else
                transform Tms::Transforms::ObjAccession::InitiationNote
              end

              if config.valuationnote_treatment == :drop
                transform Delete::Fields,
                  fields: %i[valuationnotes]
              else
                transform Prepend::ToFieldValue,
                  field: :valuationnotes,
                  value: 'Valuation note: '
              end

              if config.fields.any?(:deedofgiftsentiso)
                transform Prepend::ToFieldValue,
                  field: :deedofgiftsentiso,
                  value: 'Deed of gift sent: '
              end
              if config.fields.any?(:deedofgiftreceivediso)
                transform Prepend::ToFieldValue,
                  field: :deedofgiftreceivediso,
                  value: 'Deed of gift received: '
              end

              unless config.proviso_sources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.proviso_sources,
                  target: :acquisitionprovisos,
                  sep: "\n",
                  delete_sources: true
              end
              unless config.note_sources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.note_sources,
                  target: :acquisitionnote,
                  sep: "\n",
                  delete_sources: true
              end
              unless config.reason_sources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.reason_sources,
                  target: :acquisitionreason,
                  sep: "\n",
                  delete_sources: true
              end

              transform Rename::Fields, fieldmap: {
                authorizer_person: :acquisitionauthorizer,
                accessionisodate: :accessiondategroup,
                accessionmethod: :acquisitionmethod
              }

              transform Delete::Fields,
                fields: %i[authdate]
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :acquisitionnumber,
                find: '\|',
                replace: '%PIPE%'
            end
          end
        end
      end
    end
  end
end
