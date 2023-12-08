# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        # Mixins for ForObjects Inscription treatment merger classes
        #
        # Requires the following instance variables or methods be defined in
        #   including class:
        #
        # - targets
        # - prefix
        # - to_pad (define by calling get_to_pad)
        module ForObjectsInscribable
          def derive_note(mergerow)
            parts = [
              mergerow[:authorname],
              mergerow[:textdate]
            ].reject(&:blank?)
            parts.empty? ? "%NULLVALUE%" : parts.join(", ")
          end
          private :derive_note

          def prefix_fields(fields)
            fields.map { |field| "#{prefix}_#{field}".to_sym }
          end
          private :prefix_fields

          def get_to_pad
            diff = Tms::Objects.text_inscription_target_fields - targets
            return [] if diff.empty?

            prefix_fields(diff)
          end
          private :get_to_pad

          def pad(row)
            to_pad.each { |field| row[field] = "%NULLVALUE%" }
          end
        end
      end
    end
  end
end
