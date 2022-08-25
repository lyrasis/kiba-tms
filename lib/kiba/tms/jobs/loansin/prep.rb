# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loansin
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :loans__in,
                destination: :loansin__prep,
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
              
              dd_treatment = Tms::Loansin.display_date_treatment
              if dd_treatment == :status
                %i[dispbeg dispend].each{ |src| Tms::Loansin.status_sources << src }
              end

              remarks_treatment = Tms::Loansin.remarks_treatment
              if remarks_treatment == :statusnote
                Tms::Loansin.status_sources << :rem
                Tms::Loansin.status_targets << :loanstatusnote
              end

              if Tms::LoanObjXrefs.conditions.record == :loan
                case Tms::LoanObjXrefs.conditions.field
                when :loanconditions
                  Tms::Loansin.loaninconditions_source_fields << :obj_loanconditions
                end
              end
              
              transform Rename::Fields, fieldmap: {
                loannumber: :loaninnumber,
                beginisodate: :loanindate,
                endisodate: :loanreturndate,
                loanrenewalisodate: :loanrenewalapplicationdate,
                loanstatus: :tmsloanstatus
              }

              req_map = {
                requestdate: :req_loanstatusdate,
                requestedby: :req_loanindividual
              }
              req_nils = Tms::Loansin.status_nil_append_fields(req_map)
              transform Append::NilFields, fields: req_nils unless req_nils.empty?
              transform Reshape::FieldsToFieldGroupWithConstant,
                fieldmap: req_map.merge(Tms::Loansin.status_nil_merge_fields(req_map)),
                constant_target: :req_loanstatus,
                constant_value: 'Requested'

              app_map = {
                approveddate: :app_loanstatusdate,
                approvedby: :app_loanindividual
              }
              app_nils = Tms::Loansin.status_nil_append_fields(app_map)
              transform Append::NilFields, fields: app_nils unless app_nils.empty?
              transform Reshape::FieldsToFieldGroupWithConstant,
                fieldmap: app_map.merge(Tms::Loansin.status_nil_merge_fields(app_map)),
                constant_target: :app_loanstatus,
                constant_value: 'Approved'

              agsent_map = {
                agreementsentisodate: :agsent_loanstatusdate
              }
              agsent_nils = Tms::Loansin.status_nil_append_fields(agsent_map)
              transform Append::NilFields, fields: agsent_nils unless agsent_nils.empty?
              transform Reshape::FieldsToFieldGroupWithConstant,
                fieldmap: agsent_map.merge(Tms::Loansin.status_nil_merge_fields(agsent_map)),
                constant_target: :agsent_loanstatus,
                constant_value: 'Agreement sent',
                replace_empty: false

              agrec_map = {
                agreementreceivedisodate: :agrec_loanstatusdate
              }
              agrec_nils = Tms::Loansin.status_nil_append_fields(agrec_map)
              transform Append::NilFields, fields: agrec_nils unless agrec_nils.empty?
              transform Reshape::FieldsToFieldGroupWithConstant,
                fieldmap: agrec_map.merge(Tms::Loansin.status_nil_merge_fields(agrec_map)),
                constant_target: :agrec_loanstatus,
                constant_value: 'Agreement received',
                replace_empty: false

              origloanend_map = {
                origloanenddate: :origloanend_loanstatusdate
              }
              origloanend_nils = Tms::Loansin.status_nil_append_fields(origloanend_map)
              transform Append::NilFields, fields: origloanend_nils unless origloanend_nils.empty?
              transform Reshape::FieldsToFieldGroupWithConstant,
                fieldmap: origloanend_map.merge(Tms::Loansin.status_nil_merge_fields(origloanend_map)),
                constant_target: :origloanend_loanstatus,
                constant_value: 'Original loan end',
                replace_empty: false


              if dd_treatment == :note
                transform Tms::Transforms::Loansin::DisplayDateNote, target: :display_dates_note
                Tms::Loansin.loaninnote_source_fields << :display_dates_note
              elsif dd_treatment == :conditions
                transform Tms::Transforms::Loansin::DisplayDateNote, target: :display_dates_note
                Tms::Loansin.loaninconditions_source_fields << :display_dates_note
              elsif dd_treatment == :status
                dispbeg_map = {
                  dispbegisodate: :dispbeg_loanstatusdate
                }
                dispbeg_nils = Tms::Loansin.status_nil_append_fields(dispbeg_map)
                transform Append::NilFields, fields: dispbeg_nils unless dispbeg_nils.empty?
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: dispbeg_map.merge(Tms::Loansin.status_nil_merge_fields(dispbeg_map)),
                  constant_target: :dispbeg_loanstatus,
                  constant_value: Tms::Loansin.display_date_begin_status,
                  replace_empty: false

                dispend_map = {
                  dispendisodate: :dispend_loanstatusdate
                }
                dispend_nils = Tms::Loansin.status_nil_append_fields(dispend_map)
                transform Append::NilFields, fields: dispend_nils unless dispend_nils.empty?
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: dispend_map.merge(Tms::Loansin.status_nil_merge_fields(dispend_map)),
                  constant_target: :dispend_loanstatus,
                  constant_value: Tms::Loansin.display_date_end_status,
                  replace_empty: false
              else
                warn("Unknown Tms::Loansin.display_date_treatment: #{dd_treatment}")
              end

              if remarks_treatment == :statusnote
                transform Tms::Transforms::Loansin::RemarksToStatusNote
              elsif remarks_treatment == :note
                Tms::Loansin.loaninnote_source_fields << :remarks
              else
                warn ("Unknown Loansin remarks treatment: #{remarks_treatment}")
              end

              transform Collapse::FieldsToRepeatableFieldGroup,
                sources: Tms::Loansin.status_sources,
                targets: Tms::Loansin.status_targets,
                delim: Tms.delim

              notefields = Tms::Loansin.loaninnote_source_fields
              unless notefields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: notefields,
                  target: :loaninnote,
                  sep: '%CR%%CR%',
                  delete_sources: true
              end

              transform Tms::Transforms::Loansin::InsuranceIndemnityNote
              
              conditionsfields = Tms::Loansin.loaninconditions_source_fields
              unless conditionsfields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: conditionsfields,
                  target: :loaninconditions,
                  sep: '%CR%%CR%',
                  delete_sources: true
              end

              transform Tms::Transforms::Loansin::SeparateContacts

              rolefields = %i[personrole orgrole]
              rolefields.each do |field|
                transform Warn::UnlessFieldValueMatches,
                  field: field,
                  match: 'lender',
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
                fieldmap: {lenderpersonlocal: pref},
                multikey: true,
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                lookup: persons__by_norm,
                keycolumn: :contact_norm,
                fieldmap: {lenderscontact: pref},
                multikey: true,
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                lookup: orgs__by_norm,
                keycolumn: :org_norm,
                fieldmap: {lenderorganizationlocal: pref},
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
