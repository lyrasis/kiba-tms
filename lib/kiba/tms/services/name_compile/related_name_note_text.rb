# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      module NameCompile
        # Returns formatted, labeled related name note text
        class RelatedNameNoteText
          def initialize(mode:)
            @mode = mode
            @alt_label_prefix =
              Tms::NameCompile.related_name_note_role_prefix_for_alt
            @alt_label_suffix =
              Tms::NameCompile.related_name_note_role_suffix_for_alt
          end

          def call(authtype:, name:, relator: nil)
            "#{label(authtype, relator)}: #{name}"
          end

          private

          attr_reader :mode, :alt_label_prefix, :alt_label_suffix

          def formatted_type(type)
            type.blank? ? " " : " #{type.downcase.delete_suffix("?")} "
          end

          def label(type, relator)
            return "Related#{formatted_type(type)}name" if relator.blank?
            return "Related#{formatted_type(type)}(#{relator})" if mode == :main

            "Related#{formatted_type(type)}(#{alt_label_prefix}#{relator}#{alt_label_suffix})"
          end
        end
      end
    end
  end
end
