# frozen_string_literal: true

module Kiba
  module Tms
    # Config for processing TMS ObjDeaccession table data
    #
    # Note on field name typo: YES, "displosal". Someone made, then
    # copy/pasted a typo when these fields were originally added to
    # CS. No one caught it at the time, and once the fields can be
    # used in the wild, it's an application- breaking change to fix
    # the names, so DISPLOSAL
    module ObjDeaccession
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      # @!group Prep settings

      # @return [nil, Proc] Kiba.job_segment of transforms run at beginning of
      #   :prep__obj_deaccession job.
      setting :pre_prep_xforms, default: nil, reader: true

      # @return [nil, Proc] Kiba.job_segment of transforms run at end of
      #   :prep__obj_deaccession job.
      setting :post_prep_xforms, default: nil, reader: true

      # @!endgroup

      # @!group Shape settings

      # How to convert ObjDeaccession rows to Object Exit procedures. This
      #   is applied by the ObjDeaccession::Shape job.
      #
      # * `:one_to_one` - each ObjDeaccession row becomes an Object Exit
      #   procedure
      # * `:per_sale` - one Object Exit is created per unique :salenumber value.
      #
      # Note for any "collapsing" treatment (e.g. not :one_to_one):
      # TMS does not enforce the same values in date or other fields
      # be entered for all records with the same :salenumber value. In
      # target fields that are not derived by aggregating values, the
      # value of the first row collapsed into the group will be used.
      # Make sure to verify that this treatment works for the client's
      # data.
      #
      # @return [:per_sale, :one_to_one] Overall strategy for converting
      #   ObjDeaccession rows to Object Exits
      setting :treatment, default: :one_to_one, reader: true

      # @return [Array<Symbol>] fields to delete at beginning of Shape job
      setting :shape_delete_fields, default: [], reader: true

      # @return [Array<Symbol>] fields remaining at beginning of Shape job
      def shape_content_fields
        Tms.headers_for(:prep__obj_deaccession) - shape_delete_fields
      end

      def date_fields
        %i[approvalisodate1 reportisodate
          saleisodate].select { |fld| shape_content_fields.include?(fld) }
      end

      # @return [nil, Proc] Kiba.job_segment of transforms run at beginning of
      #   :obj_deaccession__shape job.
      setting :pre_shape_xforms, default: nil, reader: true

      # @return [nil, Proc] Kiba.job_segment of transforms run at end of
      #   :obj_deaccession__shape job.
      setting :post_shape_xforms, default: nil, reader: true

      # @return [nil, Proc] Kiba.job_segment of transforms to build
      #   custom :exitnumber field. Run after pre_shape/initial
      #   transforms. Should add a :customexitnumber field, which will
      #   be renamed after all other processing
      setting :exitnumber_xforms, default: nil, reader: true

      # @return [:approvalstatusdate, :authorizationdate]
      setting :approvalisodate1_treatment,
        default: :approvalstatusdate,
        reader: true

      # @return [String] value of :deaccessionapprovalstatus field
      #   paired with :deaccessionapprovaldate; has no effect if
      #   :approvalisodate1_treatment is not :approvalstatusdate
      setting :approvalisodate1_status, default: "approved", reader: true

      # @return [:approvalstatusdate, :exitnote, :displosalnote,
      #   :displosalprovisos]
      setting :reportisodate_treatment,
        default: :approvalstatusdate,
        reader: true

      # @return [String] value of :deaccessionapprovalstatus field paired with
      #   :deaccessionapprovaldate; has no effect if :reportisodate_treatment is
      #   not :approvalstatusdate
      setting :reportisodate_status, default: "sale reported", reader: true

      # @return [:approvalstatusdate, :deaccessiondate, :exitdategroup,
      #   :disposaldate]
      setting :saleisodate_treatment,
        default: :disposaldate,
        reader: true

      # @return [String] value of :deaccessionapprovalstatus field paired with
      #   :deaccessionapprovaldate; has no effect if :saleisodate_treatment is
      #   not :approvalstatusdate
      setting :saleisodate_status, default: "sale", reader: true

      # @return [Array<Symbol>] field values to concatenate into :exitnote
      setting :exitnote_sources,
        default: [:remarks],
        reader: true,
        constructor: ->(base) do
          base << :reportisodate if reportisodate_treatment == :exitnote
          base
        end

      # @return [Array<Symbol>] field values to concatenate into :displosalnote
      #   [sic]
      setting :displosalnote_sources,
        default: [],
        reader: true,
        constructor: ->(base) do
          case treatment
          when :per_sale
            base.unshift(:salenumbernote, :lots)
          when :one_to_one
            %i[estimatelow estimatehigh proceedsrcvdisodate].each do |fld|
              base << fld
            end
          end

          base << :reportisodate if reportisodate_treatment == :displosalnote
          base
        end

      # @return [Array<Symbol>] field values to concatenate into
      #   :displosalprovisos [sic]
      setting :displosalprovisos_sources,
        default: %i[terms],
        reader: true,
        constructor: ->(base) do
          base << :reportisodate if reportisodate_treatment == :displosalnote
          base
        end

      # @return [String] prefix added to :estimatelow value if this field is
      #   mapped to a note
      setting :estimatelow_note_prefix,
        default: "Lowest estimated value: ",
        reader: true

      # @return [String] prefix added to :estimatehigh value if this field is
      #   mapped to a note
      setting :estimatehigh_note_prefix,
        default: "Highest estimated value: ",
        reader: true

      # @return [String] prefix added to :proceedsrcvdisodate value if
      #   this field is mapped to a note
      setting :proceedsrcvdisodate_note_prefix,
        default: "Proceeds received: ",
        reader: true

      # @return [String] prefix added to :reportisodate value if
      #   this field is mapped to a note
      setting :reportisodate_note_prefix,
        default: "Sale reported: ",
        reader: true

      # @return [String] prefix added to :salenumber value if
      #   this field is mapped to a note
      setting :salenumber_note_prefix,
        default: "Sale: ",
        reader: true

      # @return [String] prefix added to aggregated :lots value if
      #   this field is mapped to a note
      setting :lots_note_prefix,
        default: "Sale lots: ",
        reader: true

      setting :deaccessionapproval_grouped_fields,
        default: %i[deaccessionapprovaldate],
        reader: true

      setting :deaccessionapproval_main_field,
        default: :deaccessionapprovalstatus,
        reader: true

      setting :deaccessionapproval_source_fields,
        default: %i[],
        reader: true,
        constructor: ->(base) do
          settings.select { |setting|
            treatment?(setting) &&
              approval_group?(setting)
          }.map { |setting| setting.to_s.delete_suffix("_treatment").to_sym }
        end

      def treatment?(setting) = setting.to_s.end_with?("_treatment")

      def approval_group?(setting) = config.send(setting)
        .to_s
        .start_with?("approvalstatus")

      setting :deaccessionapproval_target_fields,
        default: %i[],
        reader: true,
        constructor: ->(base) do
          [deaccessionapproval_main_field,
            deaccessionapproval_grouped_fields].flatten
        end

      def rename_map
        base = {
          recipient_person: :disposalrecipientpersonlocal,
          recipient_org: :disposalrecipientorganizationlocal
        }

        base[:netsaleamount] = :displosalvalue if treatment == :one_to_one
        date_fields.each do |fld|
          trtmt = send("#{fld}_treatment".to_sym)
          next if trtmt == :approvalstatusdate

          base[fld] = trtmt
        end

        cleaned = base.select { |key, val| shape_content_fields.include?(key) }
        cleaned[:customexitnumber] = :exitnumber if exitnumber_xforms
        cleaned
      end

      # @return [Array<Symbol>] CS Object Exit notes
      def note_fields = %i[exitnote displosalnote displosalprovisos]

      # @return [Array<Symbol>] source fields that are mapped to Object Exit
      #   notes
      def note_sources
        note_fields.map { |nf| send("#{nf}_sources".to_sym) }
          .flatten
      end
      # @!endgroup

      # @!group Valuation Control extraction settings

      # @return [Array<Symbol>] names of fields where a valuation control
      #   procedures should be created for each field value
      setting :valuation_source_fields,
        default: [:netsaleamount],
        reader: true

      # @return [Hash{Symbol=>Symbol, nil}] key is field being mapped
      #   to valuation control procedure; value is field from which to
      #   set the valuation control date
      setting :valuation_date_sources,
        default: {
          netsaleamount: :saleisodate
        },
        reader: true

      # @return [Hash{Symbol=>String, nil}] key is field being mapped
      #   to valuation control procedure; value is String to use as
      #   value type in procedure
      setting :valuation_types,
        default: {
          netsaleamount: "deaccession value"
        },
        reader: true

      # @return [Hash{Symbol=>Proc, nil}] key is field being
      #   mapped to valuation control procedure; value is
      #   Kiba.job_segment proc to create note field
      setting :valuation_note_creation_xforms,
        default: {
          netsaleamount: Kiba.job_segment do
            transform Kiba::Tms::Transforms::ObjDeaccession::NetsaleamountNote
            transform Prepend::ToFieldValue,
              field: :salenumber,
              value: "Sale: "
            transform Prepend::ToFieldValue,
              field: :lotnumber,
              value: "Lot: "
            transform CombineValues::FromFieldsWithDelimiter,
              sources: %i[salenumber lotnumber],
              target: :salenote,
              delim: "; "
          end
        },
        reader: true

      # @return [Hash{Symbol=>Array<Symbol>}] key is field being
      #   mapped to valuation control procedure; value is Array of
      #   fields to combine to create the valuation procedure note. These
      #   fields will generally be created by transforms indicated in
      #   valuation_note_creation_xforms
      setting :valuation_note_sources,
        default: {
          netsaleamount: %i[salenote estimatenote]
        },
        reader: true

      # @return [Hash{Symbol=>String, nil}] key is field being
      #   mapped to valuation control procedure; value is base name of
      #   ObjDeaccession field from which to derive valueSource values
      setting :valuation_sources,
        default: {
          netsaleamount: "recipient"
        },
        reader: true

      # @return [Array<Symbol>] fields to retain in derived valuation control
      #   procedures
      def valuation_control_fields
        %i[deaccessionid objectnumber idbase] +
          Tms::Valuationcontrols.cs_fields[Tms.cspace_profile]
      end

      # @!endgroup
    end
  end
end
