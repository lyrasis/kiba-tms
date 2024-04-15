# frozen_string_literal: true

module Kiba
  module Tms
    module ObjDeaccession
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      # @return [nil, Proc] Kiba.job_segment of transforms run at beginning of
      #   :prep__obj_deaccession job.
      setting :pre_prep_xforms, default: nil, reader: true

      # @return [nil, Proc] Kiba.job_segment of transforms run at end of
      #   :prep__obj_deaccession job.
      setting :post_prep_xforms, default: nil, reader: true

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
    end
  end
end
