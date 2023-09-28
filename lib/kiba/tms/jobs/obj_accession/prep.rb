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
            base = []
            if Tms::Currencies.used? &&
                config.fields.any?(Tms::Currencies.id_field)
              base << :prep__currencies
            end
            if Tms::ConRefs.for?("ObjAccession")
              base << :con_refs_for__obj_accession
            end
            if config.fields.any?(:accessionvalue) &&
                config.fields.any?(:objectvalueid)
              base << :tms__obj_insurance
            end
            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

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
                value: "-1"
              transform Tms.data_cleaner if Tms.data_cleaner

              transform Tms::Transforms::DeleteTimestamps,
                fields: config.date_fields
              transform Tms::Transforms::DeleteEmptyMoney,
                fields: %i[accessionvalue]
              transform Delete::FieldValueMatchingRegexp,
                fields: %i[objectvalueid],
                match: "^-1$"

              unless config.initial_cleaner.empty?
                config.initial_cleaner.each { |xform| transform xform }
              end

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

              if curr.used? && config.fields.any?(curr.id_field)
                transform Merge::MultiRowLookup,
                  lookup: prep__currencies,
                  keycolumn: curr.id_field,
                  fieldmap: {curr.type_field => curr.type_field}
              end
              transform Delete::Fields, fields: curr.id_field

              if Tms::ConRefs.for?("ObjAccession")
                transform Tms::Transforms::ConRefs::Merger,
                  into: config,
                  keycolumn: :objectid
              end

              if config.fields.any?(:authorizer)
                transform Tms::Transforms::MergeUncontrolledName,
                  field: :authorizer
              end

              case config.authorizer_org_treatment
              when :drop
                transform Delete::Fields,
                  fields: :authorizer_org
              when :approvalgroup
                transform Rename::Field,
                  from: :authorizer_org,
                  to: :orgauth_approvalgroup
                transform Merge::ConstantValueConditional,
                  fieldmap: {orgauth_approvalstatus: "authorized"},
                  condition: ->(row) do
                    val = row[:orgauth_approvalgroup]
                    !val.blank?
                  end
                transform do |row|
                  row[:orgauth_approvaldate] = nil
                  val = row[:orgauth_approvalgroup]
                  next row if val.blank?

                  authdate = row[:authdate]
                  row[:orgauth_approvaldate] = if authdate.blank?
                    "%NULLVALUE%"
                  else
                    authdate
                  end
                  row
                end
              else
                transform Prepend::ToFieldValue,
                  field: :authorizer_org,
                  value: config.authorizer_org_prefix
              end

              case config.authorizer_note_treatment
              when :drop
                transform Delete::Fields,
                  fields: :authorizer_note
              when :approvalgroup
                transform Rename::Field,
                  from: :authorizer_note,
                  to: :noteauth_approvalgroup
                transform Merge::ConstantValueConditional,
                  fieldmap: {noteauth_approvalstatus: "authorized"},
                  condition: ->(row) do
                    val = row[:noteauth_approvalgroup]
                    !val.blank?
                  end
                transform do |row|
                  row[:noteauth_approvaldate] = nil
                  val = row[:noteauth_approvalgroup]
                  next row if val.blank?

                  authdate = row[:authdate]
                  row[:noteauth_approvaldate] = if authdate.blank?
                    "%NULLVALUE%"
                  else
                    authdate
                  end
                  row
                end
              else
                transform Prepend::ToFieldValue,
                  field: :authorizer_note,
                  value: config.authorizer_note_prefix
              end

              if config.auth_date_source_pref
                transform Tms::Transforms::ObjAccession::AuthDateSetter
              else
                transform Rename::Field,
                  from: :authdate,
                  to: :acquisitionauthorizerdate
              end

              approvaldates = config.fields.select do |field|
                field.to_s.start_with?("approvaliso")
              end
              unless approvaldates.empty?
                case config.approval_date_treatment
                when :drop
                  transform Delete::Fields,
                    fields: %i[approvalisodate1 approvalisodate2]
                when :approvalgroup
                  approvaldates.each do |field|
                    transform Tms::Transforms::DeriveFieldPair,
                      source: field,
                      sourcebecomes: :approvaldate,
                      newfield: :approvalstatus,
                      value: config.send("#{field}_status".to_sym)
                  end
                else
                  if config.approval_date_note_format == :combined
                    transform CombineValues::FromFieldsWithDelimiter,
                      sources: approvaldates,
                      target: :approvaldate_note,
                      delim: ", ",
                      delete_sources: true
                    transform Prepend::ToFieldValue,
                      field: :approvaldate_note,
                      value: config.approval_date_note_combined_prefix
                  else
                    if approvaldates.include?(:approvalisodate1)
                      transform Prepend::ToFieldValue,
                        field: :approvalisodate1,
                        value: config.approval_date_note_1_prefix
                    end

                    if approvaldates.include?(:approvalisodate2)
                      transform Prepend::ToFieldValue,
                        field: :approvalisodate2,
                        value: config.approval_date_note_2_prefix
                    end
                  end
                end
              end

              case config.initiation_treatment
              when :drop
                transform Delete::Fields,
                  fields: %i[initiator initdate]
              when :approvalgroup
                transform Tms::Transforms::MergeUncontrolledName,
                  field: :initiator

                %w[person org note].each do |type|
                  prefixes = {
                    "person" => "indivinit",
                    "org" => "orginit",
                    "note" => "noteinit"
                  }
                  targets = {
                    "person" => "approvalindividual",
                    "org" => "approvalgroup",
                    "note" => "approvalgroup"
                  }
                  targetfield = "#{prefixes[type]}_#{targets[type]}".to_sym
                  transform Rename::Field,
                    from: "initiator_#{type}".to_sym,
                    to: targetfield
                  transform Merge::ConstantValueConditional,
                    fieldmap: {
                      "#{prefixes[type]}_approvalstatus".to_sym => "initiated"
                    },
                    condition: ->(row) do
                      val = row[targetfield]
                      !val.blank?
                    end
                  transform do |row|
                    datefield = "#{prefixes[type]}_approvaldate".to_sym
                    row[datefield] = nil
                    val = row[targetfield]
                    next row if val.blank?

                    initdate = row[:initdate]
                    row[datefield] = if initdate.blank?
                      "%NULLVALUE%"
                    else
                      initdate
                    end
                    row
                  end
                end
              else
                transform Tms::Transforms::ObjAccession::InitiationNote
              end
              transform Delete::Fields,
                fields: %i[initdate]

              case config.dog_dates_treatment
              when :drop
                transform Delete::Fields,
                  fields: %i[deedofgiftsentiso deedofgiftreceivediso]
              when :approvalgroup
                if config.fields.any?(:deedofgiftsentiso)
                  transform Tms::Transforms::DeriveFieldPair,
                    source: :deedofgiftsentiso,
                    sourcebecomes: :approvaldate,
                    newfield: :approvalstatus,
                    value: "deed of gift sent"
                end
                if config.fields.any?(:deedofgiftreceivediso)
                  transform Tms::Transforms::DeriveFieldPair,
                    source: :deedofgiftreceivediso,
                    sourcebecomes: :approvaldate,
                    newfield: :approvalstatus,
                    value: "deed of gift received"
                end
              else
                if config.fields.any?(:deedofgiftsentiso)
                  transform Prepend::ToFieldValue,
                    field: :deedofgiftsentiso,
                    value: "Deed of gift sent: "
                end
                if config.fields.any?(:deedofgiftreceivediso)
                  transform Prepend::ToFieldValue,
                    field: :deedofgiftreceivediso,
                    value: "Deed of gift received: "
                end
              end

              if config.valuationnote_treatment == :drop
                transform Delete::Fields,
                  fields: %i[valuationnotes]
              else
                transform Prepend::ToFieldValue,
                  field: :valuationnotes,
                  value: "Valuation note: "
              end

              unless config.proviso_sources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.proviso_sources,
                  target: :acquisitionprovisos,
                  delim: "\n",
                  delete_sources: true
              end
              unless config.note_sources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.note_sources,
                  target: :acquisitionnote,
                  delim: "\n",
                  delete_sources: true
              end
              unless config.reason_sources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.reason_sources,
                  target: :acquisitionreason,
                  delim: "\n",
                  delete_sources: true
              end

              transform Rename::Fields, fieldmap: {
                authorizer_person: :acquisitionauthorizer,
                accessionisodate: :accessiondategroup,
                accessionmethod: :acquisitionmethod
              }

              transform Clean::RegexpFindReplaceFieldVals,
                fields: :acquisitionnumber,
                find: '\|',
                replace: "%PIPE%"

              transform Delete::EmptyFieldGroups,
                groups: [
                  %i[approvalisodate1_approvalstatus
                    approvalisodate1_approvaldate],
                  %i[approvalisodate2_approvalstatus
                    approvalisodate2_approvaldate],
                  %i[deedofgiftsentiso_approvalstatus
                    deedofgiftsentiso_approvaldate],
                  %i[deedofgiftreceivediso_approvalstatus
                    deedofgiftreceivediso_approvaldate]
                ], delim: "|"

              transform Collapse::FieldsToRepeatableFieldGroup,
                sources: config.approval_source_fields,
                targets: config.approval_target_fields,
                delim: Tms.delim
            end
          end
        end
      end
    end
  end
end
