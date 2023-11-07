# frozen_string_literal: true

module Kiba
  module Tms
    module Loansin
      extend Dry::Configurable

      module_function

      # Indicates what job output to use as the base for non-TMS-table-sourced
      #   modules
      setting :source_job_key, default: :loans__in, reader: true
      extend Tms::Mixins::Tableable

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
      setting :display_date_begin_status, default: "Display begin", reader: true
      # @return [String] used as status value of end dates if
      #   treatment == :status
      setting :display_date_end_status, default: "Display end", reader: true
      # @return [String] prepended to display date value for concatenation into
      #   note field
      setting :display_date_note_label, default: "Displayed: ", reader: true

      # @return [:statusnote, :note] target field for remarks data
      setting :remarks_treatment, default: :statusnote, reader: true
      # @return [String] used by Loansin::RemarksToStatusNote transform to split
      #   remarks field data into separate status notes
      setting :remarks_delim, default: Tms.notedelim, reader: true
      # @return [String] used by Loansin::RemarksToStatusNote transform as the
      #   constant value for status on derived status notes
      setting :remarks_status, default: "Note", reader: true

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
          if Tms::ObjAccession.loaned_object_treatment == :creditline_to_loanin
            value << :cl
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
          value
        }

      # @return [Array<Symbol>] fields to concatenated into target note field
      setting :note_source_fields,
        default: %i[description],
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

      # @return [Array<Symbol>] fields to concatenated into target conditions
      #   field
      setting :conditions_source_fields,
        default: %i[loanconditions insind],
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
            value << :text_entry
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
