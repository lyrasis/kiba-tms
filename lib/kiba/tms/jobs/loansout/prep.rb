# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loansout
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :loans__out,
                destination: :loansout__prep,
                lookup: %i[
                           orgs__by_norm
                           persons__by_norm
                          ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::EmptyFields
              
              dd_treatment = Tms::Loansout.display_date_treatment
              case dd_treatment
                when :status
                  %i[dispbeg dispend].each{ |src| Tms::Loansout.status_sources << src }
              when :note
                Tms::Loansout.loanoutnote_source_fields << :display_dates_note
              when :conditions
                Tms::Loansout.specialconditionsofloan_source_fields << :display_dates_note
              else
                warn ("Unknown Loansout display date treatment: #{dd_treatment}")
              end

              remarks_treatment = Tms::Loansout.remarks_treatment
              case remarks_treatment
                when :statusnote
                Tms::Loansout.status_sources << :rem
                Tms::Loansout.status_targets << :loanstatusnote
              when :note
                Tms::Loansout.loanoutnote_source_fields << :remarks
              else
                warn ("Unknown Loansout remarks treatment: #{remarks_treatment}")
              end

              if Tms::LoanObjXrefs.conditions.record == :loan
                case Tms::LoanObjXrefs.conditions.field
                when :loanconditions
                  Tms::Loansout.specialconditionsofloan_source_fields << :obj_loanconditions
                end
              end
              
              transform Rename::Fields, fieldmap: {
                loannumber: :loanoutnumber,
                beginisodate: :loanoutdate,
                endisodate: :loanreturndate,
                loanrenewalisodate: :loanrenewalapplicationdate,
                loanstatus: :tmsloanstatus
              }

              req_map = {
                requestdate: :req_loanstatusdate,
                requestedby: :req_loanindividual
              }
              req_nils = Tms::Loansout.status_nil_append_fields(req_map)
              transform Append::NilFields, fields: req_nils unless req_nils.empty?
              transform Reshape::FieldsToFieldGroupWithConstant,
                fieldmap: req_map.merge(Tms::Loansout.status_nil_merge_fields(req_map)),
                constant_target: :req_loanstatus,
                constant_value: 'Requested'

              app_map = {
                approveddate: :app_loanstatusdate,
                approvedby: :app_loanindividual
              }
              app_nils = Tms::Loansout.status_nil_append_fields(app_map)
              transform Append::NilFields, fields: app_nils unless app_nils.empty?
              transform Reshape::FieldsToFieldGroupWithConstant,
                fieldmap: app_map.merge(Tms::Loansout.status_nil_merge_fields(app_map)),
                constant_target: :app_loanstatus,
                constant_value: 'Approved'

              agsent_map = {
                agreementsentisodate: :agsent_loanstatusdate
              }
              agsent_nils = Tms::Loansout.status_nil_append_fields(agsent_map)
              transform Append::NilFields, fields: agsent_nils unless agsent_nils.empty?
              transform Reshape::FieldsToFieldGroupWithConstant,
                fieldmap: agsent_map.merge(Tms::Loansout.status_nil_merge_fields(agsent_map)),
                constant_target: :agsent_loanstatus,
                constant_value: 'Agreement sent',
                replace_empty: false

              agrec_map = {
                agreementreceivedisodate: :agrec_loanstatusdate
              }
              agrec_nils = Tms::Loansout.status_nil_append_fields(agrec_map)
              transform Append::NilFields, fields: agrec_nils unless agrec_nils.empty?
              transform Reshape::FieldsToFieldGroupWithConstant,
                fieldmap: agrec_map.merge(Tms::Loansout.status_nil_merge_fields(agrec_map)),
                constant_target: :agrec_loanstatus,
                constant_value: 'Agreement received',
                replace_empty: false

              origloanend_map = {
                origloanenddate: :origloanend_loanstatusdate
              }
              origloanend_nils = Tms::Loansout.status_nil_append_fields(origloanend_map)
              transform Append::NilFields, fields: origloanend_nils unless origloanend_nils.empty?
              transform Reshape::FieldsToFieldGroupWithConstant,
                fieldmap: origloanend_map.merge(Tms::Loansout.status_nil_merge_fields(origloanend_map)),
                constant_target: :origloanend_loanstatus,
                constant_value: 'Original loan end',
                replace_empty: false


              if dd_treatment == :note || dd_treatment == :conditions
                transform Tms::Transforms::Loansin::DisplayDateNote, target: :display_dates_note
              elsif dd_treatment == :status
                dispbeg_map = {
                  dispbegisodate: :dispbeg_loanstatusdate
                }
                dispbeg_nils = Tms::Loansout.status_nil_append_fields(dispbeg_map)
                transform Append::NilFields, fields: dispbeg_nils unless dispbeg_nils.empty?
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: dispbeg_map.merge(Tms::Loansout.status_nil_merge_fields(dispbeg_map)),
                  constant_target: :dispbeg_loanstatus,
                  constant_value: Tms::Loansout.display_date_begin_status,
                  replace_empty: false

                dispend_map = {
                  dispendisodate: :dispend_loanstatusdate
                }
                dispend_nils = Tms::Loansout.status_nil_append_fields(dispend_map)
                transform Append::NilFields, fields: dispend_nils unless dispend_nils.empty?
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: dispend_map.merge(Tms::Loansout.status_nil_merge_fields(dispend_map)),
                  constant_target: :dispend_loanstatus,
                  constant_value: Tms::Loansout.display_date_end_status,
                  replace_empty: false
              else
                warn("Unknown Tms::Loansout.display_date_treatment: #{dd_treatment}")
              end

              if remarks_treatment == :statusnote
                transform Tms::Transforms::Loansin::RemarksToStatusNote
              end

              transform Collapse::FieldsToRepeatableFieldGroup,
                sources: Tms::Loansout.status_sources,
                targets: Tms::Loansout.status_targets,
                delim: Tms.delim

              notefields = Tms::Loansout.loanoutnote_source_fields
              unless notefields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: notefields,
                  target: :loanoutnote,
                  sep: '%CR%%CR%',
                  delete_sources: true
              end

              transform Tms::Transforms::Loansin::InsuranceIndemnityNote
              
              conditionsfields = Tms::Loansout.specialconditionsofloan_source_fields
              unless conditionsfields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: conditionsfields,
                  target: :specialconditionsofloan,
                  sep: '%CR%%CR%',
                  delete_sources: true
              end

              transform Tms::Transforms::Loansout::SeparateContacts

              rolefields = %i[personrole orgrole]
              rolefields.each do |field|
                transform Warn::UnlessFieldValueMatches,
                  field: field,
                  match: 'borrower',
                  delim: Tms.delim,
                  casesensitive: false
              end
              transform Delete::Fields, fields: rolefields

              namefields = %i[person org contact]
              namefields.each do |field|
                transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                  source: field,
                  target: "#{field}_norm".to_sym,
                  multival: true,
                  delim: Tms.delim
              end

              pref = Tms::Constituents.preferred_name_field
              
              transform Merge::MultiRowLookup,
                lookup: persons__by_norm,
                keycolumn: :person_norm,
                fieldmap: {borrowerpersonlocal: pref},
                multikey: true,
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                lookup: persons__by_norm,
                keycolumn: :contact_norm,
                fieldmap: {borrowerscontact: pref},
                multikey: true,
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                lookup: orgs__by_norm,
                keycolumn: :org_norm,
                fieldmap: {borrowerorganizationlocal: pref},
                multikey: true,
                delim: Tms.delim

              delfields = namefields + namefields.map{ |field| "#{field}_norm".to_sym }
              transform Delete::Fields, fields: delfields

              transform Tms::Transforms::Loansin::CombineLoanStatus
            end
          end
        end
      end
    end
  end
end
