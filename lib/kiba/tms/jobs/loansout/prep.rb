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
              transform Rename::Fields, fieldmap: rename_fieldmap unless rename_fieldmap.empty?

              name_lookups = Tms::Loansout.subtract_omitted_fields(
                %i[requestedby approvedby contact]
              )
              unless name_lookups.empty?
                name_lookups.each do |field|
                  normfield = "#{field}_norm".to_sym
                  transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                    source: field,
                    target: normfield,
                    multival: true,
                    delim: Tms.delim
                  transform Merge::MultiRowLookup,
                    lookup: names__by_norm,
                    keycolumn: normfield,
                    fieldmap: {field => :person},
                    multikey: true,
                    delim: Tms.delim
                  transform Delete::Fields, fields: normfield
                end
              end

              req_map = Tms::Loansout.delete_omitted_fields({
                requestdate: :req_loanstatusdate,
                requestedby: :req_loanindividual
              })
              unless req_map.empty?
                req_nils = Tms::Loansout.status_nil_append_fields(req_map)
                transform Append::NilFields, fields: req_nils unless req_nils.empty?
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: req_map.merge(Tms::Loansout.status_nil_merge_fields(req_map)),
                  constant_target: :req_loanstatus,
                  constant_value: 'Requested'
              end

              app_map = Tms::Loansout.delete_omitted_fields({
                approveddate: :app_loanstatusdate,
                approvedby: :app_loanindividual
              })
              unless app_map.empty?
                app_nils = Tms::Loansout.status_nil_append_fields(app_map)
                transform Append::NilFields, fields: app_nils unless app_nils.empty?
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: app_map.merge(Tms::Loansout.status_nil_merge_fields(app_map)),
                  constant_target: :app_loanstatus,
                  constant_value: 'Approved'
              end

              agsent_map = Tms::Loansout.delete_omitted_fields({
                agreementsentisodate: :agsent_loanstatusdate
              })
              unless agsent_map.empty?
                agsent_nils = Tms::Loansout.status_nil_append_fields(agsent_map)
                transform Append::NilFields, fields: agsent_nils unless agsent_nils.empty?
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: agsent_map.merge(Tms::Loansout.status_nil_merge_fields(agsent_map)),
                  constant_target: :agsent_loanstatus,
                  constant_value: 'Agreement sent',
                  replace_empty: false
              end

              agrec_map = Tms::Loansout.delete_omitted_fields({
                agreementreceivedisodate: :agrec_loanstatusdate
              })
              unless agrec_map.empty?
                agrec_nils = Tms::Loansout.status_nil_append_fields(agrec_map)
                transform Append::NilFields, fields: agrec_nils unless agrec_nils.empty?
                transform Reshape::FieldsToFieldGroupWithConstant,
                  fieldmap: agrec_map.merge(Tms::Loansout.status_nil_merge_fields(agrec_map)),
                  constant_target: :agrec_loanstatus,
                  constant_value: 'Agreement received',
                  replace_empty: false
              end

              unless Tms::Loansout.omitted_fields.any?(:origloanenddate)
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
              end

              if Tms::Loansout.display_dates?
                if dd_treatment == :note || dd_treatment == :conditions
                  transform Tms::Transforms::Loansin::DisplayDateNote,
                    target: :display_dates_note
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
                  sep: '%CR%%CR%',
                  delete_sources: true
              end

              transform Tms::Transforms::InsuranceIndemnityNote

              conditionsfields = Tms::Loansout.conditions_source_fields
              unless conditionsfields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: conditionsfields,
                  target: :specialconditionsofloan,
                  sep: '%CR%%CR%',
                  delete_sources: true
              end

              transform Tms::Transforms::Loansout::SeparateContacts
              transform Rename::Field, from: :contact, to: :borrowerscontact

              rolefields = %i[personrole orgrole]
              rolefields.each do |field|
                transform Warn::UnlessFieldValueMatches,
                  field: field,
                  match: 'borrower',
                  delim: Tms.delim,
                  casesensitive: false
              end
              transform Delete::Fields, fields: rolefields

              namefields = %i[person org]
              namefields.each do |field|
                transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                  source: field,
                  target: "#{field}_norm".to_sym,
                  multival: true,
                  delim: Tms.delim
              end

              transform Merge::MultiRowLookup,
                lookup: names__by_norm,
                keycolumn: :person_norm,
                fieldmap: {borrowerpersonlocal: :person},
                multikey: true,
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                lookup: names__by_norm,
                keycolumn: :org_norm,
                fieldmap: {borrowerorganizationlocal: :organization},
                multikey: true,
                delim: Tms.delim

              delfields = namefields + namefields.map do |field|
                "#{field}_norm".to_sym
              end
              transform Delete::Fields, fields: delfields

              transform Tms::Transforms::Loansin::CombineLoanStatus
            end
          end
        end
      end
    end
  end
end
