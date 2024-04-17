# frozen_string_literal: true

module Kiba
  module Tms
    module Loansin
      extend Dry::Configurable

      module_function

      # Indicates what job output to use as the base for non-TMS-table-sourced
      #   modules
      setting :source_job_key, default: :loans__in, reader: true

      setting :empty_fields,
        default: [],
        reader: true,
        constructor: ->(base) do
          [base, Tms::Loans.empty_fields].flatten.uniq
        end
      extend Tms::Mixins::Tableable

      setting :cs_record_id_field, default: :loaninnumber, reader: true
      extend Tms::Mixins::CsTargetable

      # @return [nil, Proc] Kiba.job_segment definition run at the end of
      #   loansin__cspace job
      setting :pre_ingest_xforms, default: nil, reader: true

      # If changes are made here, update docs/mapping_options/con_xrefs.adoc as
      #   needed
      setting :con_ref_name_merge_rules,
        default: {
          fcart: {
            con_contact: {
              suffixes: %w[person organization],
              merge_role: false
            },
            lender: {
              suffixes: %w[personlocal organizationlocal],
              merge_role: false
            }
          }
        },
        reader: true

      # @return [:conditions, :note] target field for merged text entries data
      setting :text_entries_treatment,
        default: :conditions,
        reader: true

      # @return [:status, :note, :conditions] target field
      setting :display_date_treatment, default: :status, reader: true
      # @return [String] used as status value of begin dates if
      #   treatment == :status
      setting :display_date_begin_status, default: "display begin", reader: true
      # @return [String] used as status value of end dates if
      #   treatment == :status
      setting :display_date_end_status, default: "display end", reader: true
      # @return [String] prepended to display date value for concatenation into
      #   note field
      setting :display_date_note_label, default: "Displayed: ", reader: true

      # @return [:statusnote, :note] target field for remarks data
      setting :remarks_treatment, default: :statusnote, reader: true

      # @return [String] used by Loansin::RemarksToStatusNote transform to split
      #   remarks field data into separate status notes
      setting :remarks_delim, default: Tms.notedelim, reader: true

      # @return [String] used by Loansin::RemarksToStatusNote transform as the
      #   `loanStatus` constant value for derived status notes
      setting :remarks_status, default: "note", reader: true

      # @return [Array<String>] of status values with no accompanying info
      #   that need to be exploded/padded out for combination in field group
      setting :custom_status_values, default: [], reader: true

      # @return [Array<Symbol>] sent to Collapse::FieldsToRepeatableFieldGroup
      #   to build status field group
      setting :status_sources,
        default: %i[req app agsent agrec origloanend],
        reader: true,
        constructor: proc { |value|
          if display_date_treatment == :status
            %i[dispbeg dispend].each { |src| value << src }
          end
          if remarks_treatment == :statusnote
            value << :rem
          end
          # Since there can be multiple objects related to a loan in, and loan
          # in credit line is nonrepeatable in CS, subsequent variant credit
          # line values are mapped to loan status note
          if Tms::ObjAccession.loaned_object_treatment == :creditline_to_loanin
            value << :cl
          end
          if Tms::LoanObjXrefs.requesteddate_treatment == :loan_status
            value << :objreq
          end
          value
        }
      # @return [Array<Symbol>] sent to Collapse::FieldsToRepeatableFieldGroup
      #   to build status field group
      setting :status_targets,
        default: %i[loanindividual loanstatus loanstatusdate],
        reader: true,
        constructor: proc { |value|
          if remarks_treatment == :statusnote
            value << :loanstatusnote
          end
          if Tms::ObjAccession.loaned_object_treatment == :creditline_to_loanin
            value << :loanstatusnote
          end
          if Tms::LoanObjXrefs.requesteddate_treatment == :loan_status
            value << :loanstatusnote
          end
          value.uniq
        }

      # @return [Array<Symbol>] fields to concatenated into target note field
      setting :note_source_fields,
        default: %i[note],
        reader: true,
        constructor: proc { |value|
          if display_date_treatment == :note
            value << :display_dates_note
          end
          if Tms::LoanObjXrefs.conditions_record == :loan &&
              Tms::LoanObjXrefs.conditions_field == :note
            value << :obj_loanconditions
          end
          value
        }

      # @return [Array<Symbol>] fields to concatenated into target conditions
      #   field
      setting :conditions_source_fields,
        default: %i[conditions],
        reader: true,
        constructor: proc { |value|
          if display_date_treatment == :conditions
            value << :display_dates_note
          end
          if Tms::LoanObjXrefs.conditions_record == :loan &&
              Tms::LoanObjXrefs.conditions_field == :conditions
            value << :obj_loanconditions
          end
          value
        }

      def status_pad_fields(fieldmap)
        prefix = fieldmap.values.first.to_s.split("_").first
        present = fieldmap.values.map do |val|
          val.to_s.delete_prefix("#{prefix}_").to_sym
        end
        (status_targets - present - [:loanstatus]).map do |val|
          "#{prefix}_#{val}".to_sym
        end
      end

      def status_nil_append_fields(fieldmap)
        needed = status_pad_fields(fieldmap)
        return [] if needed.empty?

        needed.map { |val| val.to_s.sub("_", "").to_sym }
      end

      def status_nil_merge_fields(fieldmap)
        needed = status_pad_fields(fieldmap)
        return {} if needed.empty?

        needed.map { |val| [val.to_s.sub("_", "").to_sym, val] }.to_h
      end
    end
  end
end
