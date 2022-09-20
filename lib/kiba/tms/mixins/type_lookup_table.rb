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
        # Override in extending module if different behavior is desired
        # Options: :todo, :self, :downcase
        def default_mapping_treatment
          :todo
        end
          
        def mappable_type?
          true
        end

        def post_transforms
          []
        end
        
        def pre_transforms
          []
        end

        # @param bind [Binding] of the calling module
        def xforms(bind)
          Kiba.job_segment do
            config = bind.receiver.send(:config)
            typefield = config.type_field
            origtypefield = "orig_#{typefield}".to_sym

            config.pre_transforms.each do |xform|
              transform{ |row| xform.process(row) }
            end
              
            transform Tms::Transforms::DeleteTmsFields
            transform Tms::Transforms::DeleteNoValueTypes, field: typefield

            if config.omitting_fields?
              transform Delete::Fields, fields: config.omitted_fields
            end

            if config.mappable_type?
              transform Rename::Field, from: typefield, to: origtypefield
              transform Replace::FieldValueWithStaticMapping,
                source: origtypefield,
                target: typefield,
                mapping: config.mappings,
                fallback_val: nil,
                delete_source: false
            end

            config.post_transforms.each do |xform|
              transform{ |row| xform.process(row) }
            end
          end
        end

        # @param bind [Binding] of the calling module
        def multitable_xforms(bind)
          Kiba.job_segment do
            config = bind.receiver.send(:config)
            typefield = config.type_field
            origtypefield = "orig_#{typefield}".to_sym
            
            config.pre_transforms.each do |xform|
              transform{ |row| xform.process(row) }
            end
              
            transform Tms::Transforms::DeleteTmsFields
            transform Tms::Transforms::DeleteNoValueTypes, field: typefield
            if config.omitting_fields?
              transform Delete::Fields, fields: config.omitted_fields
            end
            if config.mappable_type?
              transform Rename::Field, from: typefield, to: origtypefield
              transform Replace::FieldValueWithStaticMapping,
                source: origtypefield,
                target: typefield,
                mapping: config.mappings,
                fallback_val: nil,
                delete_source: false
            end
            transform Tms::Transforms::TmsTableNames

            config.post_transforms.each do |xform|
              transform{ |row| xform.process(row) }
            end
          end
        end
      end
    end
  end
end
