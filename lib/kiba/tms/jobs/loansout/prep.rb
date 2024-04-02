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
              loanout_fields = config.content_fields
              remarks_treatment = Tms::Loansout.remarks_treatment

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              rename_fieldmap = {
                loannumber: :loanoutnumber,
                beginisodate: :loanoutdate,
                endisodate: :loanreturndate,
                loanrenewalisodate: :loanrenewalapplicationdate,
                loanstatus: :tmsloanstatus
              }.select { |key, val| loanout_fields.include?(key) }
              transform Rename::Fields, fieldmap: rename_fieldmap

              transform Tms::Transforms::Loansout::Approvedby

              statuses = {
                req: {
                  value: {
                    loangroup: :requestedby_org,
                    loanindividual: :requestedby_person,
                    loanstatusdate: :requestdate
                  },
                  constant: {loanstatus: "requested"}
                },
                agsent: {
                  value: {loanstatusdate: :agreementsentisodate},
                  constant: {loanstatus: "agreement sent"}
                },
                agrec: {
                  value: {loanstatusdate: :agreementreceivedisodate},
                  constant: {loanstatus: "agreement received"}
                },
                tms: {
                  value: {loanstatus: :tmsloanstatus},
                  constant: {}
                }
              }

              if loanout_fields.include?(:origloanenddate)
                statuses[:origloanend] = {
                  value: {loanstatusdate: :origloanenddate},
                  constant: {loanstatus: "original loan end"}
                }
              end

              if config.display_dates? && dd_treatment == :status
                statuses[:dispbeg] = {
                  value: {loanstatusdate: :dispbegisodate},
                  constant: {loanstatus: config.display_date_begin_status}
                }
                statuses[:dispend] = {
                  value: {loanstatusdate: :dispendisodate},
                  constant: {loanstatus: config.display_date_end_status}
                }
              end

              if remarks_treatment == :statusnote
                statuses[:rem] = {
                  value: {loanstatusnote: :remarks},
                  constant: {loanstatus: config.remarks_status}
                }
              end

              statuses.each do |prefix, data|
                status_builder = Tms::Transforms::FieldGroupSources.new(
                  grouped_fields: config.status_targets,
                  prefix: prefix.to_s,
                  value_map: data[:value],
                  constant_map: data[:constant]
                )
                transform do |row|
                  vals = data[:value].values
                    .map { |field| row[field] }
                    .reject(&:blank?)
                  newrow = if vals.empty?
                    row
                  else
                    status_builder.process(row)
                  end
                  data[:value].values.each { |field| newrow.delete(field) }
                  newrow
                end
              end

              if Tms::Loansout.display_dates?
                if dd_treatment == :note || dd_treatment == :conditions
                  transform Tms::Transforms::Loansin::DisplayDateNote,
                    target: :display_dates_note
                else
                  unless dd_treatment == :status
                    warn("Unknown Tms::Loansout.display_date_treatment: "\
                         "#{dd_treatment}")
                  end
                end
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
                  delim: Tms.notedelim,
                  delete_sources: true
              end

              transform Tms::Transforms::InsuranceIndemnityNote

              conditionsfields = Tms::Loansout.conditions_source_fields
              unless conditionsfields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: conditionsfields,
                  target: :specialconditionsofloan,
                  delim: Tms.notedelim,
                  delete_sources: true
              end

              if Tms::ConRefs.for?("Loansout")
                if config.con_ref_name_merge_rules
                  transform Tms::Transforms::ConRefs::Merger,
                    into: config,
                    keycolumn: :loanid
                end
              end

              # Prefer contact (person name) as borrowers contact
              transform do |row|
                val = row[:contact_person]
                row.delete(:contact_person)
                row[:borrowerscontact] = nil
                next row if val.blank?

                row[:borrowerscontact] = val
                row
              end

              # If no contact (person name), set first merged-in
              # contact as :borrowerscontact. Remaning merged-in
              # contacts mapped to :borrowerscontact_extra. If there's
              # already a contact (person name), all merged-in
              # contacts not duplicating that value are mapped to
              # :borrowerscontact_extra.
              transform do |row|
                merged_contact = row[:borrowerscontactperson]
                row.delete(:borrowerscontactperson)
                row[:borrowerscontact_extra] = nil
                next row if merged_contact.blank?

                merged_vals = merged_contact.split(Tms.delim)
                contact = row[:borrowerscontact]
                if contact.blank?
                  row[:borrowerscontact] = merged_vals.shift
                else
                  merged_vals.reject! { |val| val == contact }
                end

                unless merged_vals.empty?
                  row[:borrowerscontact_extra] = merged_vals.join(Tms.delim)
                end

                row
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contact_org borrowerscontactorg],
                target: :borrowerscontact_org,
                delim: Tms.delim
              transform Deduplicate::FieldValues,
                fields: :borrowerscontact_org,
                sep: Tms.delim

              # If there is only :borrowerpersonlocal, do nothing: the
              # person is the borrower. If there is
              # :borrowerpersonlocal and :borrowerorganizationlocal,
              # the organization is the borrower. What to do with the
              # :borrowerpersonlocal value in this case depends. If
              # there is no :borrowerscontact value, it is mapped
              # there. Otherwise, it is mapped to :borrower_extra.
              transform do |row|
                row[:borrower_extra] = nil
                bp = row[:borrowerpersonlocal]
                next row if bp.blank?

                bo = row[:borrowerorganizationlocal]
                if bo.blank?
                  next row #:borrowerpersonlocal is borrower value
                else
                  row[:borrowerpersonlocal] = nil
                  bc = row[:borrowerscontact]
                  if bc.blank?
                    row[:borrowerscontact] = bp
                  else
                    row[:borrower_extra] = bp
                  end
                end
                row
              end

              transform Delete::EmptyFields
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
