# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module DDLanguages
      extend Dry::Configurable
      module_function

      setting :source_job_key, default: :prep__dd_languages, reader: true
      extend Tms::Mixins::Tableable

      setting :id_field, default: :languageid, reader: true
      setting :type_field, default: :language, reader: true
      setting :used_in,
        default: [
          "ReferenceMaster.#{id_field}",
          "TextEntries.#{id_field}",
          "ObjectNames.#{id_field}",
          "ObjTitles.#{id_field}",
          "Terms.#{id_field}",
          "TermSourceLanguages.#{id_field}",
          "ThesaurusBases.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def mappable_type?
        false
      end

      def pre_transforms
        [
          Delete::FieldsExcept.new(
                fields: %i[languageid mnemonic label]
              ),
          Tms::Transforms::DDLanguages::PopulateLanguage.new,
          Tms::Transforms::DDLanguages::FormatLanguage.new
        ]
      end
    end
  end
end
