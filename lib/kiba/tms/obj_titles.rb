# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjTitles
      module_function
      extend Dry::Configurable

      setting :delete_fields, default: %i[titleid displayed isexhtitle], reader: true
      setting :empty_fields, default: %i[], reader: true
      setting :migrate_inactive, default: false, reader: true
      # transform should add :titlenote field and delete :remarks and :dateeffectiveisodate
      setting :note_creator, default: Tms::Transforms::ObjTitles::TitleNoteCreator, reader: true
    end
  end
end
