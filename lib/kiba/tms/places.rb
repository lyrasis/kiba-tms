# frozen_string_literal: true

module Kiba
  module Tms
    module Places
      extend Dry::Configurable

      module_function

      # Indicates what job output to use as the base for non-TMS-table-sourced
      #   modules
      setting :source_job_key, default: :places__compile,
        reader: true
      extend Tms::Mixins::Tableable

      # Content fields whose values will be treated hierarchically. Should be
      #   be ordered narrow-to-broad. For example, with the default values,
      #   you may get a hierarchical authority term like:
      #   Durham -- Durham (county) -- North Carolina -- USA -- North America
      #
      # We can optionally build a Place authority hierarchy involving values
      #   in these fields
      #
      # :subregion is omitted because, based on client data reviews, this field
      #   is used to describe various levels of subregion, such that it is
      #   impossible to place the values at any one place in the hierarchy. For
      #   example, "Appalachia, Southern" would be a subregion of Appalachia,
      #   while being broader than individual state. Conversely, "Piedmont" or
      #   "Sand Hills" might be assigned as subregions of North Carolina, thus
      #   narrower than state.
      # :culturalregion is omitted for the same reasons as :subregion
      setting :hierarchy_fields,
        default: %i[locus building locale township city county
                    state river politicalregion region country nation
                    continent],
        reader: true

      # Value inserted between segments when combining TMS field values into a
      #   single hierarchical term in CS
      setting :hierarchy_separator,
        default: " < ",
        reader: true

      # For reporting -- the original TMS place source fields that are not
      #   categorized as hierarchy fields
      def non_hierarchy_fields
        @non_hierarchy_fields ||= Tms::Places.source_fields -
          Tms::Places.hierarchy_fields -
          Tms::Places.worksheet_added_fields
      end

      # If true, if unique nonhierarchical term list includes identical
      #   terms from different source fields, the name of the source field
      #   is appended to the term value (in parentheses)
      setting :qualify_non_hierarchical_terms,
        default: true,
        reader: true
      # String value prepended to source field name in parentheses if
      #   :qualify_non_hierarchical_terms = true. This is useful at initial
      #   processing stages, as it allows terms qualified in this way to be
      #   easily separated from terms that have parentheticals in their
      #   actual data values, for analysis of how many terms are affected
      #   and whether qualification should be turned off.
      setting :nonhier_qualifier_prefix,
        default: "fieldsrc:",
        reader: true

      # Whether to remove parts of terms indicating proximity (near, or close
      #   to) from the values that will become authority terms, moving these
      #   strings to a separate :proximity field, which can be merged in as
      #   role or note field value associated with a particular use of the
      #   term in an object record.
      #
      # You may want this set to `false` if:
      #
      # - You want to have separate authority terms for "Paris" and
      #   "near Paris"; or
      # - Your type_to_object_field_mapping includes CS object fields
      #   without associated role, type, or note field per place value
      setting :proximity_as_note,
        default: true,
        reader: true

      # Same as `:proximity_as_note`, but for parts of terms indicating
      #   uncertainty, like "(?)", "possibly", or "probably"
      setting :uncertainty_as_note,
        default: true,
        reader: true

      # Project-specific regular expression patterns matching non-proximity or
      #   uncertainty strings that should be removed from authority term values,
      #   and included in a note when term is used in object record
      setting :misc_note_patterns,
        default: [],
        reader: true,
        constructor: ->(value) do
          value.map{ |pattern| [pattern, "patternmatch"] }
            .to_h
        end

      # The note fields that may be generated by the three above settings. These
      #   fields contain values that must be removed for authority extraction
      #   and processing
      setting :derived_note_fields,
        default: [],
        reader: true,
        constructor: ->(value) do
          value << :proximity if proximity_as_note
          value << :uncertainty if uncertainty_as_note
          value << :misc_note unless misc_note_patterns.empty?
          value
        end

      # -----------------------------------------------------------------------
      # Proximity and uncertainty pattern-related settings
      # -----------------------------------------------------------------------
      #
      # These are only used if we are treating :proximity_as_note and/or
      #   :uncertainty_as_note. If so, these are used for two purposes:
      # - String segments matching the patterns are deleted from any values in
      #   which they appear when we are extracting the unique values from which
      #   to create authority terms
      # - If the pattern (left side of =>) matches a field value in a row, the
      #   term (from right side of =>) is added to a :proximity, and/or
      #   :uncertainty field in that row. These field values can then be used
      #   to qualify specific uses of the now generic, authorized place term (in
      #   role, type, or note field associated with field into which the place
      #   value is mapped.
      #
      # - default - common patterns expected across datasets
      # - removed - allows us to remove any default pattern that is
      #   problematic for the project data
      # - custom - allows us to override the term added to note for a given
      #   default pattern, and also add new patterns specific to project
      #   data set
      #
      # DATA LOSS WARNING:
      # If proximity/uncertainty indicators are extracted to notes, but the
      #   place values with which they are associated are mapped to a CS
      #   place authority-controlled field which does not have an associated
      #   role, type, or note field for each value, the specific
      #   proximity and/or uncertainty indicators will be lost in the migration
      #
      # IMPLEMENTATION NOTES:
      # If both proximity and uncertainty are being treated as notes, make sure
      #   that indicator terms have been mapped to :proximity and :uncertainty
      #   fields for BOTH before any deleting/cleaning any patterns from the
      #   field values. Reason: Deleting matching proximity patterns may cause
      #   uncertainty patterns not to match, and vice versa.
      #
      # To redefine an existing default pattern with a different term to be
      #   merged into notes, just add it to the custom pattern setting; you do
      #   not need to add it to removed AND custom pattern settings.
      setting :default_proximity_patterns,
        default: {
          /\(above\)/=>"above",
          /^near /=>"near",
          /\(near\??\)/i=>"near",
          /, near/=>"near",
          /\(outside\)/=>"exterior",
          /\(head of\??\)/=>"head of",
          /\(south of\??\)/=>"south of"
        },
        reader: true

      setting :removed_proximity_patterns,
        default: [],
        reader: true

      setting :custom_proximity_patterns,
        default: {},
        reader: true

      setting :default_uncertainty_patterns,
        default: {
          /\(\?\)/=>"uncertain",
          /\? *$/=>"uncertain",
          / \? /=>"uncertain",
          / *\(probably\) */=>"probable",
          /^probably /=>"probable"
        },
        reader: true

      setting :removed_uncertainty_patterns,
        default: [],
        reader: true

      setting :custom_uncertainty_patterns,
        default: {},
        reader: true

      # Derives actual proximity patterns from default, removed, and custom
      #   settings
      def proximity_patterns
        abstract_patterns("proximity")
      end

      # Derives actual uncertainty patterns from default, removed, and custom
      #   settings
      def uncertainty_patterns
        abstract_patterns("uncertainty")
      end

      # Derives all patterns to be deleted from authority term values, from
      #  proximity, uncertainty, and misc_note settings
      def delete_patterns
        base = [misc_note_patterns.keys]
        base << proximity_patterns.keys if proximity_as_note
        base << uncertainty_patterns.keys if uncertainty_as_note
        base << /\(\)/ unless base.empty?
        base.flatten
      end

      # ------------------------------------------------------------------------
      # Cleanup related settings - initial cleanup (from TMS table structure to
      #   terms)
      # ------------------------------------------------------------------------
      # List provided worksheets, most recent first. Assumes they
      #   are in the client project directory/to_client subdir
      setting :worksheets,
        default: [],
        reader: true,
        constructor: proc { |value|
          value.map do |filename|
            File.join(Kiba::Tms.datadir, "to_client", filename)
          end
        }

      # List returned/completed worksheet files, oldest first, newest last.
      #   Assumes they are in the client project directory/supplied subdir
      setting :returned,
        default: [],
        reader: true,
        constructor: proc { |value|
          value.map do |filename|
            File.join(Kiba::Tms.datadir, "supplied", filename)
          end
        }

      # Indicates whether any cleanup has been returned. If not,
      #   we run everything on base data. If yes, we merge in/overlay cleanup on
      #   the affected base data tables
      def cleanup_done
        !returned.empty?
      end

      # String used to delimit/split multiple :norm_fingerprint values in cleanup
      #   process
      setting :norm_fingerprint_delim, default: "////", reader: true

      def worksheet_jobs
        worksheets.map.with_index do |filename, idx|
          "places__worksheet_provided_#{idx}".to_sym
        end
      end

      def returned_jobs
        returned.map.with_index do |filename, idx|
          "places__worksheet_returned_#{idx}".to_sym
        end
      end

      # ------------------------------------------------------------------------
      # Final cleanup related settings - ensuring consistency of terms derived
      #   in initial cleanup, and indicating variants
      # ------------------------------------------------------------------------
      # List returned/completed worksheet files, oldest first, newest last.
      #   Assumes they are in the client project directory/supplied subdir
      setting :final_returned,
        default: [],
        reader: true,
        constructor: proc { |value|
          value.map do |filename|
            File.join(Kiba::Tms.datadir, "supplied", filename)
          end
        }

      # Indicates whether any cleanup has been returned. If not,
      #   we run everything on base data. If yes, we merge in/overlay cleanup on
      #   the affected base data tables
      def final_cleanup_done
        !returned.empty?
      end

      def final_returned_jobs
        final_returned.map.with_index do |filename, idx|
          "places__final_worksheet_returned_#{idx}".to_sym
        end
      end

      # Fields from which fingerprint is created in cleanup worksheet
      setting :final_wksht_fp_fields,
              default: %i[place add_variant],
              reader: true

      # ------------------------------------------------------------------------
      # More technical settings
      # ------------------------------------------------------------------------

      # Array of registry entries to use as sources for :places__compiled
      #
      # IMPLEMENTATION NOTE: Jobs used as sources here should provide the
      #   following fields:
      #
      # - :orig_combined
      #
      # Also, make sure to remove any non-authority term-contributing fields
      def compile_sources
        base = []
        if Tms::ObjGeography.used? && !(
          Tms::ObjGeography.controlled_types == :none
        )
          base << :obj_geography__for_authority
        end
        if Tms::ConGeography.used? && !(
          Tms::ConGeography.controlled_types == :none
        )
          base << :con_geography__for_authority
        end
        base << :reference_master__places if Tms::ReferenceMaster.used?
        base
      end

      def source_fields
        base = []
        if Tms::ObjGeography.used? && !(
          Tms::ObjGeography.controlled_types == :none
        )
          base << Tms::ObjGeography.content_fields
        end
        if Tms::ConGeography.used? && !(
          Tms::ConGeography.controlled_types == :none
        )
          base << Tms::ConGeography.content_fields
        end
        base << :placepublished if Tms::ReferenceMaster.used?
        base << worksheet_added_fields
        base.flatten!
        base - %i[orig_combined norm_combined]
      end

      setting :worksheet_added_fields,
        default: %i[uncontrolled_value proximity_note uncertainty_note
                    place_note],
        reader: true

      def worksheet_columns
        base = []
        base << :to_review if cleanup_done
        base << hierarchy_fields.reverse
        base << (source_fields - hierarchy_fields)
        base << worksheet_added_fields
        base << %i[occurrences norm_combineds norm_fingerprints
                   clean_fingerprint]
        base.flatten.uniq
      end

      def abstract_patterns(type)
        return {} unless send("#{type}_as_note".to_sym)

        default = send("default_#{type}_patterns".to_sym)
        removed = send("removed_#{type}_patterns".to_sym)
        custom = send("custom_#{type}_patterns".to_sym)

        base = if removed.empty?
                 default
               else
                 newdefault = default.dup
                 removed.each do |pattern|
                   newdefault.delete(pattern)
                 end
                 newdefault
               end
        custom.keys.each do |pattern|
          next unless base.key?(pattern)

          base.delete(pattern)
        end
        custom.merge(base)
      end
      private_class_method :abstract_patterns
    end
  end
end
