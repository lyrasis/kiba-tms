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
        def self.extended(mod)
          self.check_required_manual_settings(mod)
          self.set_mappings_setting(mod)
        end

        def is_type_lookup_table?
          true
        end

        # Override in extending module if different behavior is desired
        # Options: :todo, :self, :downcase
        def default_mapping_treatment
          :todo
        end

        # If true, the prep transform copies the original type value to a new
        #   field (for auditing purposes), and replaces the remaining type value
        #   with mapped value from the extending config's :mappings setting.
        #
        # Manually define as false in the extending config to skip that behavior
        def mappable_type?
          true
        end

        # example of use: Tms::Countries
        def post_transforms
          []
        end

        # example of use: Tms::DDLanguages
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

        def self.check_required_manual_settings(mod)
          %i[id_field type_field used_in].each do |setting|
            next if mod.respond_to?(setting)

            msg = "#{mod} needs #{setting} defined to extend TypeLookupTable"
            warn(msg)
          end
        end
        private_class_method :check_required_manual_settings

        def self.set_mappings_setting(mod)
          return if mod.respond_to?(:mappings)

          mod.module_eval('setting :mappings, default: {}, reader: true')
        end
        private_class_method :set_mappings_setting
      end
    end
  end
end
