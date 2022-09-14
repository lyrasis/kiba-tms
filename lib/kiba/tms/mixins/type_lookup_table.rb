# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      # ## Implementation details
      #
      # Modules mixing this in must:
      #
      # - `extend Tms::Mixins::TypeLookupTable`
      module TypeLookupTable
        def type_lookup
          true
        end

        # @param bind [Binding] of the calling module
        def xforms(bind)
          Kiba.job_segment do
            config = bind.receiver.send(:config)
            typefield = config.type_field
            origtypefield = "orig_#{typefield}".to_sym
            
            transform Tms::Transforms::DeleteTmsFields
            transform Tms::Transforms::DeleteNoValueTypes, field: typefield
            if config.omitting_fields?
              transform Delete::Fields, fields: config.omitted_fields
            end
            transform Rename::Field, from: typefield, to: origtypefield
            transform Replace::FieldValueWithStaticMapping,
              source: origtypefield,
              target: typefield,
              mapping: config.mappings,
              fallback_val: nil,
              delete_source: false
          end
        end

        # @param bind [Binding] of the calling module
        def multitable_xforms(bind)
          Kiba.job_segment do
            config = bind.receiver.send(:config)
            typefield = config.type_field
            origtypefield = "orig_#{typefield}".to_sym
            
            transform Tms::Transforms::DeleteTmsFields
            transform Tms::Transforms::DeleteNoValueTypes, field: typefield
            if config.omitting_fields?
              transform Delete::Fields, fields: config.omitted_fields
            end
            transform Rename::Field, from: typefield, to: origtypefield
            transform Replace::FieldValueWithStaticMapping,
              source: origtypefield,
              target: typefield,
              mapping: config.mappings,
              fallback_val: nil,
              delete_source: false
            transform Tms::Transforms::TmsTableNames
          end
        end
      end
    end
  end
end
