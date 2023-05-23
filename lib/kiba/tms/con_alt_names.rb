# frozen_string_literal: true

module Kiba
  module Tms
    module ConAltNames
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      # Alt name strings to treat as anonymous - used by
      #   ConAltNames::QualifyAnonymous transform if `:qualify_anonymous`
      #   is true. Values are downcased for matching.
      setting :consider_anonymous, default: ["anonymous"], reader: true
      # Whether to run ConAltNames::QualifyAnonymous transform, which appends
      #   main name parenthetical to any alt name value that matches values
      #   in :consider_anonymous
      setting :qualify_anonymous, default: true, reader: true
    end
  end
end
