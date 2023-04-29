# frozen_string_literal: true

module Kiba
  module Tms
    module FolderTypes
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :foldertypeid, reader: true
      setting :type_field, default: :foldertype, reader: true
      setting :used_in,
        default: [
          "PackageFolders.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def mappable_type?
        false
      end
    end
  end
end
