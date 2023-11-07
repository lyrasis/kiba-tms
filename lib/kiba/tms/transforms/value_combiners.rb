# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      # Mix-in module
      module ValueCombiners
        # @param vals [Array]
        # @param delim [String]
        def safe_join(vals:, delim:)
          vals.map { |val| (val == "%NULLVALUE%") ? nil : val }
            .reject(&:blank?)
            .join(delim)
        end

        # Methods to set source fields and delimiters for the different parts.
        #   Override in including classes as necessary

        # @return [String] delimiter to join multiple sources into body of note
        def body_delim
          ": "
        end

        # @return [Array<Symbol>] fields whose values are joined into the body
        #   value
        def body_source_fields
          %i[remarks textentry]
        end

        # @return [String] delimiter to join multiple sources into a prefix
        #   string
        def prefix_delim
          ", "
        end

        # @return [Array<Symbol>] fields whose values are joined into the prefix
        #   value
        def prefix_source_fields
          %i[purpose textdate]
        end

        # @return [String] delimiter to prepend prefix to rest of note value
        def prefixed_delim
          ": "
        end

        # Methods that combine/aggregate the others methods into usable final
        #   field values
        # text_entry = prefix + body
        # attributed = text_entry + authors
        # labeled = given label + attributed
        def labeled(row, label)
          val = attributed(row)
          return if val.blank?

          "#{label}: #{val}"
        end

        def attributed(row)
          safe_join(
            vals: [textentry(row), authors(row)],
            delim: " "
          )
        end

        def prefixed_body(row)
          thebody = body(row)
          return "" if thebody.blank?

          safe_join(
            vals: [prefix(row), thebody],
            delim: prefixed_delim
          )
        end
        alias_method :textentry, :prefixed_body

        def labeled_body(row, label)
          thebody = body(row)
          return "" if thebody.blank?

          safe_join(
            vals: [label, thebody],
            delim: prefixed_delim
          )
        end

        # Methods that create the combinable sub-methods
        def prefix(row)
          safe_join(
            vals: prefix_source_fields.map { |field| row[field] },
            delim: prefix_delim
          )
        end

        def body(row)
          safe_join(
            vals: body_source_fields.map { |field| row[field] },
            delim: body_delim
          )
        end

        def authors(row)
          vals = [row[:person_author], row[:org_author]].reject(&:blank?)
          return if vals.empty?

          "--#{vals.join(", ")}"
        end

        # Methods that create combinable sub-methods from given parts, not
        #   set variables/defined methods in including class
        def build_body(*partvals)
          safe_join(vals: partvals, delim: body_delim)
        end

        def labeled_value(label, value)
          safe_join(vals: [label, value], delim: prefixed_delim)
        end
      end
    end
  end
end
