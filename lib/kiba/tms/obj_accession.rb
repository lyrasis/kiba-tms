# frozen_string_literal: true

module Kiba
  module Tms
    # Most of the settings in this module are documented at:
    #   https://github.com/lyrasis/kiba-tms/blob/main/doc/mapping_options/obj_accessions.adoc
    module ObjAccession
      extend Dry::Configurable

      module_function

      setting :id_uniquifier_separator,
        default: " uniq ",
        reader: true

      # CollectionSpace domain profiles where the Acquisition record contains
      #   the approval group fields
      setting :approval_group_profiles,
        default: %i[core anthro bonsai fcart lhmc publicart],
        reader: true

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
        default: "Original Value",
        reader: true
      setting :approval_date_treatment,
        default: nil,
        reader: true,
        constructor: ->(_val) do
          return :approvalgroup if approval_group_profiles.include?(
            Tms.cspace_profile
          )

          :acquisitionnote
        end
      setting :approvalisodate1_status,
        default: "approved",
        reader: true
      setting :approvalisodate2_status,
        default: "approved (subsequent)",
        reader: true
      setting :approval_date_note_format,
        default: :combined,
        reader: true
      setting :approval_date_note_combined_prefix,
        default: "Approval date(s): ",
        reader: true
      setting :approval_date_note_1_prefix,
        default: "Initial approval date: ",
        reader: true
      setting :approval_date_note_2_prefix,
        default: "Subsequent approval date: ",
        reader: true
      setting :auth_date_source_pref,
        default: nil,
        reader: true,
        constructor: ->(_val) do
          return nil if approval_group_profiles.include?(Tms.cspace_profile)

          %i[authdate approvalisodate1 approvalisodate2]
        end

      setting :authorizer_org_treatment,
        default: nil,
        reader: true,
        constructor: ->(_val) do
          return :approvalgroup if approval_group_profiles.include?(
            Tms.cspace_profile
          )

          :acquisitionnote
        end
      setting :authorizer_org_prefix,
        default: "Authorized by (organization name): ",
        reader: true

      setting :authorizer_note_treatment,
        default: :acquisitionnote,
        reader: true,
        constructor: ->(_val) do
          return :approvalgroup if approval_group_profiles.include?(
            Tms.cspace_profile
          )

          :acquisitionnote
        end
      setting :authorizer_note_prefix,
        default: "Authorizer note: ",
        reader: true

      setting :initiation_treatment,
        default: nil,
        reader: true,
        constructor: ->(_val) do
          return :approvalgroup if approval_group_profiles.include?(
            Tms.cspace_profile
          )

          :acquisitionreason
        end
      setting :initiation_prefix,
        default: "Initiated: ",
        reader: true

      setting :dog_dates_treatment,
        default: nil,
        reader: true,
        constructor: ->(_val) do
          return :approvalgroup if approval_group_profiles.include?(
            Tms.cspace_profile
          )

          :acquisitionnote
        end

      setting :loaned_object_treatment,
        default: :creditline_to_loanin,
        reader: true
      setting :percentowned_treatment,
        default: :acquisitionprovisos,
        reader: true
      setting :percentowned_prefix,
        default: "Percent owned: ",
        reader: true
      setting :valuationnote_treatment,
        default: :acquisitionnote,
        reader: true
      setting :valuationnote_prefix,
        default: "Valuation note: ",
        reader: true

      setting :con_ref_name_merge_rules,
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

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[currencyamount currencyrate localamount
          accessionminutes1 accessionminutes2 budget capitalprogram
          currencyid originalentityid currententityid],
        reader: true,
        constructor: proc { |value| set_deletes(value) }
      extend Tms::Mixins::Tableable

      # Transforms to be applied in `:prep__obj_accession` job, after
      #  omitted fields are deleted and general data_cleaner is
      #  applied. Should be kiba-compliant transform class, requiring
      #  no initialization parameters
      #
      # @return [Array<#process>]
      setting :initial_cleaner,
        default: [],
        reader: true

      # Transforms to be applied as the final step of the
      #  `:prep__obj_accession` job. Should be kiba-compliant
      #  transform class, requiring no initialization parameters
      #
      # @return [Array<#process>]
      setting :post_prep_cleaner,
        default: [],
        reader: true

      setting :name_fields,
        default: %i[authorizer initiator],
        reader: true
      extend Tms::Mixins::UncontrolledNameCompileable

      setting :date_fields,
        default: %i[accessionisodate authdate
          approvalisodate1 approvalisodate2
          initdate suggestedvalueisodate],
        reader: true,
        constructor: proc { |value| value.select { |f| fields.any?(f) } }

      # approaches required for creation of CS acquisitions and obj/acq
      #   relations
      #   options: :onetone, :lotnumber, :linkedlot, :linkedset
      #   see: https://github.com/lyrasis/kiba-tms/blob/main/doc/data_preparation_details/acquisitions.adoc
      setting :processing_approaches, default: %i[one_to_one], reader: true

      # Defines how auto-generated config settings are populated
      setting :configurable,
        default: {
          processing_approaches: proc {
            Tms::Services::ObjAccession::ProcessingApproachDeriver.call
          }
        },
        reader: true

      def proviso_sources
        base = %i[acquisitionterms]
        field = :acquisitionprovisos
        if approval_date_treatment == field
          case approval_date_note_format
          when :combined
            base << :approvaldate_note
          when :separate
            base << :approvalisodate1 if fields.any?(:approvalisodate1)
            base << :approvalisodate2 if fields.any?(:approvalisodate2)
          end
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
        if valuationnote_treatment == field
          base << :valuationnotes
        end
        base << :te_proviso_note if Tms::TextEntries.for?("ObjAccession")
        base.flatten
      end

      def note_sources
        base = %i[source remarks]
        field = :acquisitionnote
        if approval_date_treatment == field
          case approval_date_note_format
          when :combined
            base << :approvaldate_note
          when :separate
            base << :approvalisodate1 if fields.any?(:approvalisodate1)
            base << :approvalisodate2 if fields.any?(:approvalisodate2)
          end
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
        if valuationnote_treatment == field
          base << :valuationnotes
        end
        base << :te_acquisition_note if Tms::TextEntries.for?("ObjAccession")
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
        if dog_dates_treatment == :drop
          value << %i[deedofgiftsentiso deedofgiftreceivediso]
        end
        if percentowned_treatment == :drop
          value << :currpercentownership
        end
        value.flatten
      end
      private :set_deletes

      # -----------------------------------------------------------------------
      # REPEATABLE FIELD GROUP COLLAPSE CONFIG
      # -----------------------------------------------------------------------
      #
      # Data from various sources may be merged into intermediate table
      #   for later combination into a single repeatable field group.
      #
      # The settings in this section define the intermediate fields
      #   and field group structure used to generate `sources` and
      #   `targets` parameters for the
      #   `Collapse::FieldsToRepeatableFieldGroup` transform used to
      #   do this field group collapsing.
      #
      # This assumes intermediate field naming conventions so that the
      #   source fields values are intermediate field name prefixes
      #   separated from the remainder of the field name by an
      #   underscore, and the rest of the field name does not contain
      #   any underscores. For example, the intermediate fields
      #   containing approval date 1 data that will become an approval group
      #   row would be:
      #
      # - appdate1_approvalstatus
      # - appdate1_approvaldate
      # -----------------------------------------------------------------------
      setting :approval_source_fields,
        default: %i[],
        reader: true,
        constructor: ->(default) do
          if approval_date_treatment == :approvalgroup
            default << %i[approvalisodate1 approvalisodate2]
          end
          default << :orgauth if authorizer_org_treatment == :approvalgroup
          default << :noteauth if authorizer_note_treatment == :approvalgroup
          if initiation_treatment == :approvalgroup
            default << %i[indivinit orginit noteinit]
          end
          if dog_dates_treatment == :approvalgroup
            default << %i[deedofgiftsentiso deedofgiftreceivediso]
          end
          default << :te if Tms::TextEntries.for?("ObjAccession")
          default.flatten
        end
      setting :approval_target_fields,
        default: %i[approvalgroup approvalindividual approvalstatus
          approvaldate],
        reader: true,
        constructor: ->(val) do
          val << :approvalnote if Tms::TextEntries.for?("ObjAccession")
        end
    end
  end
end
