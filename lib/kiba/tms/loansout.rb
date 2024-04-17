# frozen_string_literal: true

module Kiba
  module Tms
    module Loansout
      extend Dry::Configurable

      module_function

      # Indicates what job output to use as the base for non-TMS-table-sourced
      #   modules
      setting :source_job_key, default: :loans__out, reader: true
      extend Tms::Mixins::Tableable

      setting :cs_record_id_field, default: :loanoutnumber, reader: true
      extend Tms::Mixins::CsTargetable

      # In general, the :approvedby field only has one value, which is a person
      # name. In those cases, the `:approvedby_handling` setting fully controls
      # how the :approvedby value will be treated.
      #
      # Because the `lendersAuthorizer` and `borrowersAuthorizer` fields are
      # controlled by the Person authority in CS, any :approvedby value that has
      # been categorized as an organization name will be mapped to `loanGroup`
      # in the Loan status field group block. The accompanying `loanStatus`
      # value will be set to "approved" and `loanStatusDate` will be set to
      # the value of TMS :approveddate.
      #
      # If there are more than one person names in :approvedby, the
      # subsequent names will be mapped to `loanIndividual` in the Loan
      # status field group block. The accompanying `loanStatus` value
      # will be set to "approved" and `loanStatusDate` will be set to
      # the value of TMS :approveddate.
      #
      # @return [:lender, :borrower] How to map initial person name
      #   value in :approvedby field. If :lender, the person name will
      #   map to the `lendersAuthorizer` field, and :approveddate value
      #   will map to `lendersAuthorizationDate` field. If :borrow, the person
      #   name will map to `borrowersAuthorizer` field and :approveddate will
      #   map to `borrowersAuthorizationDate`.
      setting :approvedby_handling, default: :lender, reader: true

      # If changes are made here, update docs/mapping_options/con_xrefs.adoc as
      #   needed
      setting :con_ref_name_merge_rules,
        default: {
          fcart: {
            borrower: {
              suffixes: %w[personlocal organizationlocal],
              merge_role: false
            },
            borrowerscontact: {
              suffixes: %w[person org],
              merge_role: false
            }
          }
        },
        reader: true
      # Tms::Loans has this setting so that it can be set once for loans in and
      # out.
      # @return [Array<Symbol>] fields to concatenated into target conditions
      #   field
      setting :conditions_source_fields,
        default: %i[conditions],
        reader: true,
        constructor: proc { |value|
          if display_date_treatment == :conditions
            value << :display_dates_note
          end
          if remarks_treatment == :conditions
            value << :remarks
          end
          if Tms::TextEntries.for?("Loans") &&
              text_entries_treatment == :conditions
            value = value << :text_entry
          end
          if Tms::LoanObjXrefs.conditions_record == :loan &&
              Tms::LoanObjXrefs.conditions_field == :conditions
            value << :obj_loanconditions
          end
          value
        }
      setting :display_date_treatment, default: :status, reader: true
      # @return [String] used as status value of begin dates if
      #   treatment == :status
      setting :display_date_begin_status, default: "Display begin", reader: true
      # @return [String] used as status value of end dates if
      #   treatment == :status
      setting :display_date_end_status, default: "Display end", reader: true
      # @return [String] prepended to display date value for concatenation into
      #   note field
      setting :display_date_note_label, default: "Displayed: ", reader: true
      # @return [Array<Symbol>] fields to concatenated into target note field
      setting :note_source_fields,
        default: %i[note],
        reader: true,
        constructor: proc { |value|
          if display_date_treatment == :note
            value << :display_dates_note
          end
          if remarks_treatment == :note
            value << :remarks
          end
          if Tms::TextEntries.for?("Loans") && text_entries_treatment == :note
            value << :text_entry
          end
          if Tms::LoanObjXrefs.conditions_record == :loan &&
              Tms::LoanObjXrefs.conditions_field == :note
            value << :obj_loanconditions
          end
          value
        }
      # @return [:statusnote, :note, :conditions] target field for remarks data
      setting :remarks_treatment, default: :note, reader: true
      # @return [String] used by Loansin::RemarksToStatusNote transform to split
      #   remarks field data into separate status notes
      setting :remarks_delim, default: Tms.notedelim, reader: true

      # @return [String] used as the `loanStatus` constant value for derived
      #   status notes if `:remarks_treatment` = `:statusnote`
      setting :remarks_status, default: "note", reader: true

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
          value << :tms
          value
        }
      # @return [Array<Symbol>] sent to Collapse::FieldsToRepeatableFieldGroup
      #   to build status field group
      setting :status_targets,
        default: %i[loangroup loanindividual loanstatus loanstatusdate],
        reader: true,
        constructor: proc { |value|
          if remarks_treatment == :statusnote
            value << :loanstatusnote
          end
          value
        }
      # @return [:conditions, :note] target field for merged text entries data
      setting :text_entries_treatment,
        default: :conditions,
        reader: true

      def display_dates?
        true unless (%i[dispbegisodate
          dispendisodate] - omitted_fields).empty?
      end

      def status_pad_fields(fieldmap)
        prefix = fieldmap.values.first.to_s.split("_").first
        present = fieldmap.values.map { |val|
          val.to_s.delete_prefix("#{prefix}_").to_sym
        }
        (status_targets - present - [:loanstatus]).map { |val|
          "#{prefix}_#{val}".to_sym
        }
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
