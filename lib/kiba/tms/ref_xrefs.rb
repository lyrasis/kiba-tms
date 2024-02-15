# frozen_string_literal: true

module Kiba
  module Tms
    module RefXRefs
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable
      extend Tms::Mixins::MultiTableMergeable

      setting :illustrated_mapping,
        default: {"1" => "Illustration", "0" => "No illustration"},
        reader: true

      setting :citation_note_builder,
        default: Tms::Transforms::RefXRefs::NoteBuilder,
        reader: true
    end
  end
end
