# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjAccession
      extend Dry::Configurable
      module_function

      # What to do with accessionvalue data
      # - :valuation_control - VC procedure created, linked to Acquisition
      #   procedure, and each linked object
      setting :accessionvalue_treatment,
        default: :valuation_control,
        reader: true
      # The :valuetype value used in valuation control procedures created from
      #   this and related tables. Only used when :accessionvalue_treatment
      #   = :valuation_control
      setting :accessionvalue_type,
        default: 'Original Value',
        reader: true
      setting :approval_date_2_treatment,
        default: :acquisitionnote,
        reader: true
      setting :approval_date_2_prefix,
        default: 'Subsequent approval date: ',
        reader: true
      setting :authorizer_org_treatment,
        default: :acquisitionnote,
        reader: true
      setting :authorizer_org_prefix,
        default: 'Authorized by (organization name): ',
        reader: true
      setting :authorizer_note_treatment,
        default: :acquisitionnote,
        reader: true
      setting :authorizer_note_prefix,
        default: 'Authorizer note: ',
        reader: true
      setting :dog_dates_treatment,
        default: :acquisitionnote,
        reader: true
      setting :initiation_treatment,
        default: :acquisitionreason,
        reader: true
      setting :initiation_prefix,
        default: 'Initiated: ',
        reader: true
      setting :percentowned_treatment,
        default: :acquisitionprovisos,
        reader: true
      setting :percentowned_prefix,
        default: 'Percent owned: ',
        reader: true

      setting :con_ref_field_rules,
        default: {
          fcart: {
            acquisitionsource: {
              suffixes: %w[personlocal organizationlocal],
              merge_role: false
            },
            owner: {
              suffixes: %w[personlocal organizationlocal],
              merge_role: false
            }
          }
        },
        reader: true

      setting :delete_fields,
        default: %i[currencyamount currencyrate localamount
                    accessionminutes1 accessionminutes2 budget capitalprogram
                    currencyid originalentityid currententityid],
        reader: true,
        constructor: Proc.new{ |value| set_deletes(value) }
      extend Tms::Mixins::Tableable

      setting :name_fields,
        default: %i[authorizer initiator],
        reader: true
      extend Tms::Mixins::UncontrolledNameCompileable

      # approaches required for creation of CS acquisitions and obj/acq
      #   relations
      #   options: :onetone, :lotnumber, :linkedlot, :linkedset
      #   see: https://github.com/lyrasis/kiba-tms/blob/main/doc/data_preparation_details/acquisitions.adoc
      setting :processing_approaches, default: %i[one_to_one], reader: true

      setting :configurable,
        default: {
          processing_approaches: proc{
            Tms::Services::ObjAccession::ProcessingApproachDeriver.call
          }
        },
        reader: true

      def proviso_sources
        base = %i[acquisitionterms]
        field = :acquisitionprovisos
        if approval_date_2_treatment == field
          base << :approvalisodate2
        end
        if authorizer_note_treatment == field
          base << :authorizer_note
        end
        if authorizer_org_treatment == field
          base << :authorizer_org
        end
        if dog_dates_treatment == field
          base << %i[deedofgiftsentiso deedofgiftreceivediso]
        end
        if initiation_treatment == field
          base << %i[initiation_note]
        end
        if percentowned_treatment == field
          base << :currpercentownership
        end
        base.flatten
      end

      def note_sources
        base = %i[source remarks]
        field = :acquisitionnote
        if approval_date_2_treatment == field
          base << :approvalisodate2
        end
        if authorizer_note_treatment == field
          base << :authorizer_note
        end
        if authorizer_org_treatment == field
          base << :authorizer_org
        end
        if dog_dates_treatment == field
          base << %i[deedofgiftsentiso deedofgiftreceivediso]
        end
        if initiation_treatment == field
          base << %i[initiation_note]
        end
        if percentowned_treatment == :acquisitionnote
          base << :currpercentownership
        end
        base.flatten
      end

      def reason_sources
        base = %i[acqjustification]
        field = :acquisitionreason
        if authorizer_note_treatment == field
          base << :authorizer_note
        end
        if authorizer_org_treatment == field
          base << :authorizer_org
        end
        if initiation_treatment == field
          base << %i[initiation_note]
        end
        base.flatten
      end

      def set_deletes(value)
        if accessionvalue_treatment == :valuation_control
          value << :accessionvalue
        end
        if dog_dates_treatment == :drop
          value << %i[deedofgiftsentiso deedofgiftreceivediso]
        end
        if percentowned_treatment == :drop
          value << :currpercentownership
        end
        value.flatten
      end
      private :set_deletes
    end
  end
end
