# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loansin
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :loans__in,
                destination: :loansin__prep,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if Tms::ObjAccession.loaned_object_treatment ==
                :creditline_to_loanin
              base << :loan_obj_xrefs__creditlines
            end
            if Tms::LoanObjXrefs.requesteddate_treatment == :loan_status
              base << :prep__loan_obj_xrefs
            end
            base.uniq
              .select { |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              dd_treatment = config.display_date_treatment
              loanin_fields = config.content_fields
              remarks_treatment = config.remarks_treatment

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              {
                loannumber: :loaninnumber,
                beginisodate: :loanindate,
                endisodate: :loanreturndate,
                loanrenewalisodate: :loanrenewalapplicationdate,
                loanstatus: :tmsloanstatus
              }.each do |oldname, newname|
                next unless loanin_fields.include?(oldname)

                transform Rename::Field,
                  from: oldname,
                  to: newname
              end

              req_map = {
                requestdate: :req_loanstatusdate,
                requestedby_person: :req_loanindividual
              }
              req_nils = config.status_nil_append_fields(req_map)
              transform Append::NilFields, fields: req_nils
              transform Reshape::FieldsToFieldGroupWithConstant,
                fieldmap: req_map.merge(
                  config.status_nil_merge_fields(req_map)
                ),
                constant_target: :req_loanstatus,
                constant_value: "requested"

              app_map = {
                approveddate: :app_loanstatusdate,
                approvedby_person: :app_loanindividual
              }
              app_nils = config.status_nil_append_fields(app_map)
              transform Append::NilFields, fields: app_nils
              transform Reshape::FieldsToFieldGroupWithConstant,
                fieldmap: app_map.merge(
                  config.status_nil_merge_fields(app_map)
                ),
                constant_target: :app_loanstatus,
                constant_value: "approved"

              agsent_map = {
                agreementsentisodate: :agsent_loanstatusdate
              }
              agsent_nils = config.status_nil_append_fields(agsent_map)
              transform Append::NilFields, fields: agsent_nils
              transform Reshape::FieldsToFieldGroupWithConstant,
                fieldmap: agsent_map.merge(
                  config.status_nil_merge_fields(agsent_map)
                ),
                constant_target: :agsent_loanstatus,
                constant_value: "agreement sent",
                replace_empty: false

              agrec_map = {
                agreementreceivedisodate: :agrec_loanstatusdate
              }
              agrec_nils = config.status_nil_append_fields(agrec_map)
              transform Append::NilFields, fields: agrec_nils
              transform Reshape::FieldsToFieldGroupWithConstant,
                fieldmap: agrec_map.merge(
                  config.status_nil_merge_fields(agrec_map)
                ),
                constant_target: :agrec_loanstatus,
                constant_value: "agreement received",
                replace_empty: false

              if loanin_fields.include?(:origloanenddate)
                origloanend_map = {
                  origloanenddate: :origloanend_loanstatusdate
                }
                origloanend_nils = config.status_nil_append_fields(
                  origloanend_map
                )
                transform Append::NilFields, fields: origloanend_nils
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: origloanend_map.merge(
                    config.status_nil_merge_fields(origloanend_map)
                  ),
                  constant_target: :origloanend_loanstatus,
                  constant_value: "original loan end",
                  replace_empty: false
              end

              if %i[note conditions].any?(dd_treatment)
                transform Tms::Transforms::Loansin::DisplayDateNote,
                  target: :display_dates_note
              elsif dd_treatment == :status
                dispbeg_map = {
                  dispbegisodate: :dispbeg_loanstatusdate
                }
                dispbeg_nils = config.status_nil_append_fields(dispbeg_map)
                transform Append::NilFields, fields: dispbeg_nils
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: dispbeg_map.merge(
                    config.status_nil_merge_fields(dispbeg_map)
                  ),
                  constant_target: :dispbeg_loanstatus,
                  constant_value: config.display_date_begin_status,
                  replace_empty: false

                dispend_map = {
                  dispendisodate: :dispend_loanstatusdate
                }
                dispend_nils = config.status_nil_append_fields(dispend_map)
                transform Append::NilFields, fields: dispend_nils
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: dispend_map.merge(
                    config.status_nil_merge_fields(dispend_map)
                  ),
                  constant_target: :dispend_loanstatus,
                  constant_value: config.display_date_end_status,
                  replace_empty: false
              else
                warn("Unknown config.display_date_treatment: #{dd_treatment}")
              end

              if Tms::ObjAccession.loaned_object_treatment ==
                  :creditline_to_loanin
                transform Merge::MultiRowLookup,
                  lookup: loan_obj_xrefs__creditlines,
                  keycolumn: :loanid,
                  fieldmap: {creditline: :creditline},
                  conditions: ->(_r, rows) do
                    val = rows.uniq { |row| row[:creditline] }
                    return [] if val.empty?

                    [val.first]
                  end

                transform Merge::MultiRowLookup,
                  lookup: loan_obj_xrefs__creditlines,
                  keycolumn: :loanid,
                  fieldmap: {cl_loanstatusnote: :creditline},
                  constantmap: {
                    cl_loanstatus: "credit line (additional)",
                    cl_loanindividual: Tms.nullvalue,
                    cl_loanstatusdate: Tms.nullvalue
                  },
                  delim: Tms.delim,
                  conditions: ->(_r, rows) do
                    val = rows.uniq { |row| row[:creditline] }
                    return [] if val.empty? || val.length == 1

                    val[1..-1]
                  end
              end

              if Tms::LoanObjXrefs.requesteddate_treatment == :loan_status
                fieldmap = config.status_targets.map { |f|
                  Array.new(2) { "objreq_#{f}".to_sym }
                }.to_h
                transform Merge::MultiRowLookup,
                  lookup: prep__loan_obj_xrefs,
                  keycolumn: :loanid,
                  fieldmap: fieldmap
              end

              config.custom_status_values.each do |status|
                transform do |row|
                  target = "#{status}_loanstatus".to_sym
                  row[target] = nil
                  orig = row[:tmsloanstatus]
                  next row if orig.blank?
                  next row unless orig[status]

                  row[target] = status
                  row
                end
              end
              transform Delete::Fields, fields: :tmsloanstatus

              if remarks_treatment == :statusnote
                transform Tms::Transforms::Loansin::RemarksToStatusNote
              end

              transform Collapse::FieldsToRepeatableFieldGroup,
                sources: config.status_sources,
                targets: config.status_targets,
                delim: Tms.delim

              transform CombineValues::FromFieldsWithDelimiter,
                sources: config.note_source_fields,
                target: :loaninnote,
                delim: Tms.notedelim,
                delete_sources: true

              # transform Tms::Transforms::InsuranceIndemnityNote

              transform CombineValues::FromFieldsWithDelimiter,
                sources: config.conditions_source_fields,
                target: :loaninconditions,
                delim: Tms.notedelim,
                delete_sources: true

              if Tms::ConRefs.for?("Loansin")
                if config.con_ref_name_merge_rules
                  transform Tms::Transforms::ConRefs::Merger,
                    into: config,
                    keycolumn: :loanid
                end

                %W[person org].each do |type|
                  transform CombineValues::FromFieldsWithDelimiter,
                    sources: [
                      "contact_#{type}", "con_contact#{type}"
                    ].map(&:to_sym),
                    target: "contact_#{type}".to_sym,
                    delim: Tms.delim,
                    delete_sources: true
                  transform Deduplicate::FieldValues,
                    fields: "contact_#{type}".to_sym,
                    sep: Tms.delim
                end
              end

              transform Rename::Field,
                from: :contact_person,
                to: :lenderscontact
              # transform Tms::Transforms::Loansin::CombineLoanStatus
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
