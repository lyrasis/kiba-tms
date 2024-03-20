# frozen_string_literal: true

module Kiba
  module Tms
    module Loans
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[sortnumber mnemonic isforeignlender
          hasspecialrequirements],
        reader: true,
        constructor: proc { |value|
          value << :primaryconxrefid if con_link_field == :primaryconxrefid
        }

      extend Tms::Mixins::Tableable

      setting :name_fields,
        default: %i[approvedby contact requestedby],
        reader: true
      extend Tms::Mixins::UncontrolledNameCompileable

      setting :indemnity_field_label_map,
        default: {
          indemnityfromlender: "Indemnity from lender: ",
          indemnityfrompreviousvenue: "Indemnity from previous venue: ",
          indemnityatvenue: "Indemnity at venue: ",
          indemnityreturn: "Indemnity for return to lender: "
        },
        reader: true

      def indemnity_fields = indemnity_field_label_map.keys

      setting :insurance_field_label_map,
        default: {
          insurancefromlender: "Insurance from lender: ",
          insurancefrompreviousvenue: "Insurance from previous venue: ",
          insuranceatvenue: "Insurance at venue: ",
          insurancereturn: "Insurance for return to lender: "
        },
        reader: true

      def insurance_fields = insurance_field_label_map.keys

      # @return [nil, Proc] Kiba.job_segment of transforms run after external
      #   data is merged into :prep__loans job.
      setting :post_merge_xforms, default: nil, reader: true

      # @return [nil, Proc] Kiba.job_segment of transforms run at the end of
      #   :prep__loans job.
      setting :post_prep_xforms, default: nil, reader: true

      # Some TMS installs use :constituentidold, which is a direct constituent
      #   table lookup and must be merged in differently
      #
      # If :primaryconxrefid, this should be ignored and ConXrefDetails used to
      #   merge in all names, not just a primary name
      setting :con_link_field, default: :primaryconxrefid, reader: true

      setting :conditions_sources,
        default: %i[loanconditions insuranceremarks insurancecontact],
        reader: true,
        constructor: ->(base) do
          if Tms::IndemnityResponsibilities.used?
            base << :indemnityresponsibilities
          end
          if Tms::InsuranceResponsibilities.used?
            base << :insuranceresponsibilities
          end
          base
        end

      setting :note_sources,
        default: %i[description remarks],
        reader: true

      setting :record_num_merge_config,
        default: {
          sourcejob: :tms__loans,
          fieldmap: {targetrecord: :loannumber}
        }, reader: true

      # Defines how auto-generated config settings are populated
      setting :configurable,
        default: {
          con_link_field: proc {
            Tms::Services::Loans::ConLinkFieldDeriver.call
          }
        },
        reader: true
    end
  end
end
