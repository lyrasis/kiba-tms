# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      # Mix-in module
      module ValueCombiners
        # @param vals [Array]
        # @param delim [String]
        def safe_join(vals:, delim:)
          vals.reject(&:blank?)
            .join(delim)
        end

        # Methods to set source fields and delimiters for the different parts.
        #   Override in including classes as necessary
        def body_delim
          ": "
        end

        def body_source_fields
          %i[remarks textentry]
        end

        def prefix_delim
          ", "
        end

        def prefix_source_fields
          %i[purpose textdate]
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
            delim: " ")
        end

        def textentry(row)
          safe_join(
            vals: [prefix(row), body(row)],
            delim: ": ")
        end

        # Methods that create the combinable sub-methods
        def prefix(row)
          safe_join(
            vals: prefix_source_fields.map{ |field| row[field] },
            delim: prefix_delim)
        end

        def body(row)
          safe_join(
            vals: body_source_fields.map{ |field| row[field] },
            delim: body_delim)
        end

        def authors(row)
          vals = [row[:person_author], row[:org_author]].reject(&:blank?)
          return if vals.empty?

          "--#{vals.join(', ')}"
        end
      end
    end
  end
end
