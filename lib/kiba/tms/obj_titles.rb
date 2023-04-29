# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module ObjTitles
      extend Dry::Configurable

      module_function

      setting :delete_fields, default: %i[displayed isexhtitle], reader: true
      extend Tms::Mixins::Tableable

      setting :migrate_inactive, default: false, reader: true
      # transform should add :titlenote field and delete :remarks and :dateeffectiveisodate
      setting :note_creator,
        default: Tms::Transforms::ObjTitles::TitleNoteCreator, reader: true
    end
  end
end
