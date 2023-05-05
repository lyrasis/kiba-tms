# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loansout
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :loans__out,
                destination: :loansout__prep,
                lookup: :names__by_norm
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              dd_treatment = config.display_date_treatment
              remarks_treatment = Tms::Loansout.remarks_treatment

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              rename_fieldmap = Tms::Loansout.delete_omitted_fields({
                loannumber: :loanoutnumber,
                beginisodate: :loanoutdate,
                endisodate: :loanreturndate,
                loanrenewalisodate: :loanrenewalapplicationdate,
                loanstatus: :tmsloanstatus
              })
              transform Rename::Fields, fieldmap: rename_fieldmap

              # First :approved by value gets treated as authorizer. Any
              #   additional names get recorded in loan status group
              transform Tms::Transforms::ExtractFirstValueToNewField,
                source: :approvedby_person,
                newfield: :borrowersauthorizer
              transform Copy::Field,
                from: :approveddate,
                to: :borrowersauthorizationdate
              transform do |row|
                approver = row[:approvedby_person]
                next row unless approver.blank?

                row[:approveddate] = nil
                row
              end
              app_map = Tms::Loansout.delete_omitted_fields({
                approveddate: :app_loanstatusdate,
                approvedby_person: :app_loanindividual
              })
              unless app_map.empty?
                app_nils = Tms::Loansout.status_nil_append_fields(app_map)
                unless app_nils.empty?
                  transform Append::NilFields, fields: app_nils
                end
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: app_map.merge(
                    Tms::Loansout.status_nil_merge_fields(app_map)
                  ),
                  constant_target: :app_loanstatus,
                  constant_value: "Approved"
              end

              req_map = Tms::Loansout.delete_omitted_fields({
                requestdate: :req_loanstatusdate,
                requestedby_person: :req_loanindividual
              })
              unless req_map.empty?
                req_nils = Tms::Loansout.status_nil_append_fields(req_map)
                unless req_nils.empty?
                  transform Append::NilFields, fields: req_nils
                end
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: req_map.merge(
                    Tms::Loansout.status_nil_merge_fields(req_map)
                  ),
                  constant_target: :req_loanstatus,
                  constant_value: "Requested"
              end

              agsent_map = Tms::Loansout.delete_omitted_fields({
                agreementsentisodate: :agsent_loanstatusdate
              })
              unless agsent_map.empty?
                agsent_nils = Tms::Loansout.status_nil_append_fields(agsent_map)
                unless agsent_nils.empty?
                  transform Append::NilFields, fields: agsent_nils
                end
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: agsent_map.merge(
                    Tms::Loansout.status_nil_merge_fields(agsent_map)
                  ),
                  constant_target: :agsent_loanstatus,
                  constant_value: "Agreement sent",
                  replace_empty: false
              end

              agrec_map = Tms::Loansout.delete_omitted_fields({
                agreementreceivedisodate: :agrec_loanstatusdate
              })
              unless agrec_map.empty?
                agrec_nils = Tms::Loansout.status_nil_append_fields(agrec_map)
                unless agrec_nils.empty?
                  transform Append::NilFields, fields: agrec_nils
                end
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: agrec_map.merge(
                    Tms::Loansout.status_nil_merge_fields(agrec_map)
                  ),
                  constant_target: :agrec_loanstatus,
                  constant_value: "Agreement received",
                  replace_empty: false
              end

              unless Tms::Loansout.omitted_fields.any?(:origloanenddate)
                origloanend_map = {
                  origloanenddate: :origloanend_loanstatusdate
                }
                origloanend_nils = Tms::Loansout.status_nil_append_fields(
                  origloanend_map
                )
                unless origloanend_nils.empty?
                  transform Append::NilFields, fields: origloanend_nils
                end
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: origloanend_map.merge(
                    Tms::Loansout.status_nil_merge_fields(origloanend_map)
                  ),
                  constant_target: :origloanend_loanstatus,
                  constant_value: "Original loan end",
                  replace_empty: false
              end

              if Tms::Loansout.display_dates?
                if dd_treatment == :note || dd_treatment == :conditions
                  transform Tms::Transforms::Loansin::DisplayDateNote,
                    target: :display_dates_note
                elsif dd_treatment == :status
                  dispbeg_map = {
                    dispbegisodate: :dispbeg_loanstatusdate
                  }
                  dispbeg_nils = Tms::Loansout.status_nil_append_fields(
                    dispbeg_map
                  )
                  unless dispbeg_nils.empty?
                    transform Append::NilFields, fields: dispbeg_nils
                  end
                  transform Reshape::FieldsToFieldGroupWithConstant,
                    fieldmap: dispbeg_map.merge(
                      Tms::Loansout.status_nil_merge_fields(dispbeg_map)
                    ),
                    constant_target: :dispbeg_loanstatus,
                    constant_value: Tms::Loansout.display_date_begin_status,
                    replace_empty: false

                  dispend_map = {
                    dispendisodate: :dispend_loanstatusdate
                  }
                  dispend_nils = Tms::Loansout.status_nil_append_fields(
                    dispend_map
                  )
                  unless dispend_nils.empty?
                    transform Append::NilFields, fields: dispend_nils
                  end
                  transform Reshape::FieldsToFieldGroupWithConstant,
                    fieldmap: dispend_map.merge(
                      Tms::Loansout.status_nil_merge_fields(dispend_map)
                    ),
                    constant_target: :dispend_loanstatus,
                    constant_value: Tms::Loansout.display_date_end_status,
                    replace_empty: false
                else
                  warn("Unknown Tms::Loansout.display_date_treatment: "\
                       "#{dd_treatment}")
                end
              end

              if remarks_treatment == :statusnote
                transform Tms::Transforms::Loansin::RemarksToStatusNote
              end

              transform Collapse::FieldsToRepeatableFieldGroup,
                sources: Tms::Loansout.status_sources,
                targets: Tms::Loansout.status_targets,
                delim: Tms.delim

              notefields = Tms::Loansout.note_source_fields
              unless notefields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: notefields,
                  target: :loanoutnote,
                  delim: "%CR%%CR%",
                  delete_sources: true
              end

              transform Tms::Transforms::InsuranceIndemnityNote

              conditionsfields = Tms::Loansout.conditions_source_fields
              unless conditionsfields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: conditionsfields,
                  target: :specialconditionsofloan,
                  delim: "%CR%%CR%",
                  delete_sources: true
              end

              # First :approved by value gets treated as authorizer. Any
              #   additional names get recorded in loan status group
              transform Tms::Transforms::ExtractFirstValueToNewField,
                source: :contact_person,
                newfield: :borrowerscontact

              if Tms::ConRefs.for?("Loansout")
                if config.con_ref_name_merge_rules
                  transform Tms::Transforms::ConRefs::Merger,
                    into: config,
                    keycolumn: :loanid
                end
              end

              transform Tms::Transforms::Loansin::CombineLoanStatus
            end
          end
        end
      end
    end
  end
end
