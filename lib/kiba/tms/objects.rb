# frozen_string_literal: true

module Kiba
  module Tms
    module Objects
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[
          sortnumber sortnumber2 textsearchid accountability injurisdiction
          onview searchobjectnumber sortsearchnumber
          istemplate isvirtual
          usernumber4
        ],
        reader: true,
        constructor: ->(value) { value + date_fields }
      setting :empty_fields, default: {
                               loanclassid: "0",
                               objectlevelid: "0",
                               objectnameid: "0",
                               objectnamealtid: "0",
                               objecttypeid: "0",
                               publicaccess: "0",
                               subclassid: "0",
                               type: "0"
                             },
        reader: true
      extend Tms::Mixins::Tableable

      def dimensions_to_merge?
        Tms::DimItemElemXrefs.used? && Tms::DimItemElemXrefs.for?("Objects")
      end

      # -=-=-=-=-=-=-=-=-=-=-
      # PREP SETTINGS
      # -=-=-=-=-=-=-=-=-=-=-

      # Transforms to clean individual fields. These are run at the
      #   end of the :prep__objects job, so are limited to fields
      #   present in original TMS objects table. The exceptions are
      #   any fields ending with `id`, which will have had values
      #   merged in from their respective lookup tables.
      #
      # Elements should be Kiba-compliant transform classes that do
      #   not need to be initialized with arguments
      #
      # @return [Array<#process>]
      setting :field_cleaners, default: [], reader: true
      # @return [#process] transform to merge Classifications and
      #   ClassificationXRefs in if they are used
      setting :classifications_merge_xform,
        default: Tms::Transforms::Objects::Classifications,
        reader: true

      # -=-=-=-=-=-=-=-=-=-=-
      # EXTENAL DATA MERGE SETTINGS
      # -=-=-=-=-=-=-=-=-=-=-

      # @return [Hash{Class => Hash, nil}] run in order at the end of
      #   :objects__external_data_merged job. Key is a Kiba compliant
      #   transform class. Value is nil (no initialization params for
      #   class) or Hash of initialization params
      setting :post_merge_xforms, default: {}, reader: true

      # -=-=-=-=-=-=-=-=-=-=-
      # MERGED DATA PREP SETTINGS
      # -=-=-=-=-=-=-=-=-=-=-
      # @return [Hash{Class => Hash, nil}] run in order at the beginning of
      #   :objects__merged_data_prep job. Key is a Kiba compliant
      #   transform class. Value is nil (no initialization params for
      #   class) or Hash of initialization params
      setting :merged_data_cleaners, default: [], reader: true

      # @return [Hash{Class => Hash, nil}] run in order, after any
      #   :merged_data_cleaners. Key is a Kiba compliant transform
      #   class. Value is nil (no initialization params for class) or
      #   Hash of initialization params
      setting :merged_data_shapers, default: [], reader: true

      # @return [Hash{Class => Hash, nil}] run in order, at the end of
      #   the :objects__merged_data_prep job. Key is a Kiba compliant
      #   transform class. Value is nil (no initialization params for
      #   class) or Hash of initialization params
      setting :post_merged_prep_xforms, default: [], reader: true

      # -=-=-=-=-=-=-=-=-=-=-
      # SHAPE SETTINGS
      # -=-=-=-=-=-=-=-=-=-=-

      # @return [#process] custom transform to handle merged-in classifications
      #   fields
      setting :classifications_shape_xform, default: nil, reader: true

      setting :objectname_controlled_source_fields,
        default: %i[],
        reader: true
      setting :objectname_uncontrolled_source_fields,
        default: %i[],
        reader: true
      # Used by xforms to programmatically determine target field for
      #   material values
      def objectname_base_for(field)
        if objectname_controlled_source_fields.include?(field)
          :objectnamecontrolled
        elsif objectname_uncontrolled_source_fields.include?(field)
          :objectname
        end
      end
      # @return [Array<Regexp>]
      setting :objectname_uncertainty_patterns, default: [], reader: true

      # :referencenote maps each value to :bib_referencenote, setting
      #   :bib_reference to null value placeholder
      # :delete removes the field from the migration
      # @return [:referencenote, :delete] Other treatments may be developed in
      #  the future
      setting :bibliography_treatment, default: :referencenote, reader: true

      # @return [:annotation, :delete] Other treatments may be developed in
      #  the future
      setting :cataloged_treatment, default: :annotation, reader: true
      # Handles :cataloguer and :catalogueisodate, mapping to an annotation
      #   field group line.
      setting :cataloged_shape_xforms,
        default: {},
        reader: true,
        constructor: ->(base) do
          case cataloged_treatment
          when :annotation
            base.merge!({Tms::Transforms::Objects::Cataloged => nil})
          when :delete
            base.merge!({
              Delete::Fields => {fields: %i[cataloguer catalogueisodate]}
            })
          end
          base
        end

      # :referencenote maps each value to :catrais_referencenote, setting
      #   :catrais_reference to null value placeholder
      # :delete removes the field from the migration
      # @return [:referencenote, :delete] Other treatments may be developed in
      #  the future
      setting :catrais_treatment, default: :referencenote, reader: true

      # :invstatus maps "1" to "curator approved" and "0" to nil. The value is
      #   concatenated into the :inventorystatus field
      # :delete removes the field from the migration
      # @return [:invstatus, :delete] Other treatments may be developed in
      #  the future
      setting :curatorapproved_treatment, default: :invstatus, reader: true

      # :usage maps each value to :usagenote field, and provides a constant
      #   :usage value of "exhibition"
      # :delete removes the field from the migration
      # @return [:usage, :delete] Other treatments may be developed in
      #  the future
      setting :exhibitions_treatment, default: :usage, reader: true

      setting :material_controlled_source_fields,
        default: %i[],
        reader: true
      setting :material_uncontrolled_source_fields,
        default: %i[],
        reader: true
      # @return [Proc] that takes one argument (String), and, when called,
      #   returns true/falsey. Used in shaping material values.
      setting :material_is_note,
        default: ->(value) { value.length > 58 },
        reader: true
      # @return [Array<Regexp>]
      setting :material_uncertainty_patterns, default: [], reader: true
      # Used by xforms to programmatically determine target field for
      #   material values
      def material_base_for(field)
        if material_controlled_source_fields.include?(field)
          :materialcontrolled
        elsif material_uncontrolled_source_fields.include?(field)
          :material
        end
      end

      # :referencenote maps each value to :paper_referencenote, setting
      #   :paper_reference to null value placeholder
      # :delete removes the field from the migration
      # @return [:referencenote, :delete] Other treatments may be developed in
      #  the future
      setting :paperfileref_treatment, default: :referencenote, reader: true

      # :referencenote maps each value to :pubref_referencenote, setting
      #   :pubref_reference to null value placeholder
      # :delete removes the field from the migration
      # @return [:referencenote, :delete] Other treatments may be developed in
      #  the future
      setting :pubreferences_treatment, default: :referencenote, reader: true

      # @return [Hash{Class => Hash, nil}] run in order at the end of
      #   :objects__shape job. Key is a Kiba compliant transform class. Value
      #   is nil (no initialization params for class) or Hash of initialization
      #   params
      setting :post_shape_xforms, default: {}, reader: true
      # -----------------------------------------------------------------------
      # Default field-specific shape transforms
      # -----------------------------------------------------------------------
      # @param field [Symbol]
      def field_xform_for?(field)
        methodname = "#{field}_xform".to_sym
        return true if respond_to?(methodname) && send(methodname)
      end

      # Transformers to transform data in individual source fields or
      #   sets of source fields.
      #
      # If nil, default processing in prep__objects is
      #   used unless field is otherwise omitted from processing
      setting :creditline_xform,
        default: {
          Tms::Transforms::DeriveFieldPair => {
            source: :creditline,
            newfield: :annotationtype,
            value: "Credit Line",
            sourcebecomes: :annotationnote
          }
        },
        reader: true
      setting :curatorialremarks_xform,
        default: {Prepend::ToFieldValue => {
          field: :curatorialremarks,
          value: "Curatorial remarks: "
        }},
        reader: true
      setting :inscribed_xform,
        default: {
          Tms::Transforms::DeriveFieldPair => {
            source: :inscribed,
            newfield: :inscriptioncontenttype,
            value: "inscribed",
            sourcebecomes: :inscriptioncontent
          }
        },
        reader: true
      setting :markings_xform,
        default: {
          Tms::Transforms::DeriveFieldPair => {
            source: :markings,
            newfield: :inscriptioncontenttype,
            value: "",
            sourcebecomes: :inscriptioncontent
          }
        },
        reader: true
      setting :medium_xform, default: {}, reader: true
      setting :objectcount_xform,
        default: {Tms::Transforms::Objects::Objectcount => nil},
        reader: true

      # @return [String] othernumbertype value assigned to any :objectnumber2
      #   values added to othernumber field group
      setting :objectnumber2_type, default: "object number 2", reader: true
      setting :objectnumber2_xform,
        default: {Tms::Transforms::Objects::Objectnumber2 => nil},
        reader: true

      setting :onview_xform,
        default: {Delete::Fields => {fields: :onview}},
        reader: true
      setting :paperfileref_xform, default: {}, reader: true
      setting :papersupport_xform, default: {}, reader: true
      setting :publicaccess_xform,
        default: {Tms::Transforms::Objects::Publicaccess => nil},
        reader: true
      setting :pubreferences_xform, default: {}, reader: true
      setting :relatedworks_xform, default: {}, reader: true
      setting :signed_xform,
        default: {
          Tms::Transforms::DeriveFieldPair => {
            source: :signed,
            newfield: :inscriptioncontenttype,
            value: "signature",
            sourcebecomes: :inscriptioncontent
          }
        },
        reader: true

      # Default mapping will be skipped, fields will be left as-is for handling
      #   in client project
      setting :custom_map_fields, default: [], reader: true

      # @return [Hash{Symbol=>Symbol}]
      setting :base_field_rename_map,
        default: {
          description: :briefdescription,
          objectcount: :numberofobjects
        },
        reader: true,
        constructor: ->(default) do
          return default if dimensions_to_merge?

          default.merge({dimensions: :dimensionsummary})
        end
      # will be merged into :base_field_rename_map
      setting :custom_rename_fieldmap, default: {}, reader: true
      def rename_map
        tmp = {}
        custom = custom_map_fields
        base_field_rename_map.each do |from, to|
          tmp[from] = to unless custom.include?(from)
        end
        tmp.merge(custom_rename_fieldmap)
      end
      # -----------------------------------------------------------------------
      # REPEATABLE FIELD GROUP COLLAPSE CONFIG
      # -----------------------------------------------------------------------
      #
      # Data from various sources may be merged into intermediate objects table
      #   for later combination into a single repeatable field group.
      #
      # The settings in this section define the intermediate fields
      #   and field group structure used to generate `sources` and
      #   `targets` parameters for the
      #   `Collapse::FieldsToRepeatableFieldGroup` transform used to
      #   do this field group collapsing.
      #
      # This assumes intermediate field naming conventions so that the
      #   source fields values are intermediate field name prefixes
      #   separated from the remainder of the field name by an
      #   underscore, and the rest of the field name does not contain
      #   any underscores. For example, the intermediate fields
      #   containing credit line data that will become annotations
      #   would be:
      #
      # - creditline_annotationtype
      # - creditline_annotationnote
      # -----------------------------------------------------------------------
      setting :annotation_source_fields,
        default: %i[creditline],
        reader: true,
        constructor: ->(base) do
          if Tms::AltNums.for_objects_annotation_treatments_used
            base << :altnum
          end
          base << :cat if cataloged_treatment == :annotation
          base
        end
      setting :annotation_target_fields,
        default: %i[annotationtype annotationnote],
        reader: true,
        constructor: ->(base) do
          if cataloged_treatment == :annotation
            base << %i[annotationauthor annotationdate]
          end
          base.flatten
        end

      setting :assocpeople_source_fields,
        default: %i[],
        reader: true
      setting :assocpeople_target_fields,
        default: %i[assocpeople assocpeopletype assocpeoplenote],
        reader: true

      setting :assocplace_source_fields,
        default: %i[],
        reader: true
      setting :assocplace_target_fields,
        default: %i[assocplace assocplacetype assocplacenote],
        reader: true

      setting :objectname_source_fields,
        default: %i[obj],
        reader: true,
        constructor: ->(base) do
          unless objectname_controlled_source_fields.empty?
            base << objectname_controlled_source_fields
          end
          unless objectname_uncontrolled_source_fields.empty?
            base << objectname_uncontrolled_source_fields
          end
          base.flatten
        end
      setting :objectname_target_fields,
        default: %i[],
        reader: true,
        constructor: ->(base) do
          unless objectname_source_fields.empty?
            base << %i[objectnamecurrency objectnamelanguage objectnamelevel
              objectnamenote objectnamesystem objectnametype]
          end
          unless objectname_controlled_source_fields.empty?
            base << :objectnamecontrolled
          end
          unless objectname_uncontrolled_source_fields.empty?
            base << :objectname
          end
          base.flatten
        end

      setting :material_source_fields,
        default: %i[],
        reader: true,
        constructor: ->(base) do
          unless material_controlled_source_fields.empty?
            base << material_controlled_source_fields
          end
          unless material_uncontrolled_source_fields.empty?
            base << material_uncontrolled_source_fields
          end
          base.flatten
        end
      setting :material_target_fields,
        default: %i[],
        reader: true,
        constructor: ->(base) do
          unless material_source_fields.empty?
            base << %i[materialcomponent materialcomponentnote
              materialname materialsource]
          end
          unless material_controlled_source_fields.empty?
            base << :materialcontrolled
          end
          unless material_uncontrolled_source_fields.empty?
            base << :material
          end
          base.flatten
        end

      setting :nontext_inscription_source_fields, default: %i[], reader: true
      setting :nontext_inscription_target_fields, default: %i[], reader: true

      setting :reference_source_fields,
        default: %i[],
        reader: true,
        constructor: ->(base) do
          base << :bib if bibliography_treatment == :referencenote
          base << :catrais if catrais_treatment == :referencenote
          base << :paper if paperfileref_treatment == :referencenote
          base << :pubref if pubreferences_treatment == :referencenote
          base
        end
      setting :reference_target_fields,
        default: %i[reference referencenote],
        reader: true

      setting :text_inscription_source_fields,
        default: %i[signed inscribed markings],
        reader: true,
        constructor: ->(base) do
          if Tms::ObjContext.content_fields.include?(:n_signed)
            base << :nsigned
          end
        end
      setting :text_inscription_target_fields,
        default: %i[inscriptioncontenttype inscriptioncontent],
        reader: true

      setting :usage_source_fields,
        default: %i[],
        reader: true,
        constructor: ->(base) do
          if exhibitions_treatment == :usage
            base << :exh
          end
          base
        end
      setting :usage_target_fields,
        default: %i[usage usagenote],
        reader: true

      # Intermediate fields containing values to be merged into `comments`
      #   field
      #
      # @return [Array<Symbol]
      setting :comment_sources,
        reader: true,
        default: %i[notes curatorialremarks],
        constructor: ->(default) do
          default << :alt_num_comment if Tms::AltNums.used? &&
            Tms::AltNums.for?("Objects")
          default << :title_comment if Tms::ObjTitles.used?
          default
        end

      # Intermediate fields to be concatenated into contentconcept field
      #   controlled by concept/associated authority vocabulary
      setting :contentconceptconceptassociated_sources,
        default: %i[],
        reader: true

      setting :contentnote_delim, default: Tms.notedelim, reader: true
      setting :contentnote_sources,
        default: %i[con_refs_p_contentnote con_refs_o_contentnote],
        reader: true

      setting :contentdescription_delim, default: Tms.notedelim, reader: true
      setting :contentdescription_sources,
        default: %i[],
        reader: true

      setting :objecthistorynote_delim, default: Tms.notedelim, reader: true
      setting :objecthistorynote_sources,
        default: %i[provenance],
        reader: true,
        constructor: ->(base) do
          if Tms::ConXrefs.used? && Tms::ConRefs.for?("Objects")
            base << %i[con_refs_p_objecthistorynote
              con_refs_o_objecthistorynote]
          end
          base.flatten
        end

      setting :objectproductionnote_delim, default: Tms.notedelim, reader: true
      setting :objectproductionnote_sources,
        default: %i[],
        reader: true,
        constructor: ->(base) do
          return base unless Tms.cspace_profile == :fcart

          base << :histattributions
          if Tms::ConXrefs.used? && Tms::ConRefs.for?("Objects")
            base << %i[con_refs_p_objectproductionnote
              con_refs_o_objectproductionnote]
          end
          base.flatten
        end

      # Intermediate fields containing values to be merged into
      #   `inventoryStatus` field
      #
      # @return [Array<Symbol]
      setting :inventorystatus_sources,
        default: [],
        reader: true,
        constructor: ->(default) do
          default << :main_objectstatus if Tms::ObjectStatuses.used?
          default << :curatorapproved if curatorapproved_treatment == :invstatus
          default << :statusflag if Tms::StatusFlags.used?
          default << :linkedset_objectstatus if Tms::LinkedSetAcq.used?
          default
        end

      # -=-=-=-=-=-=-=-=-=-=-
      # AUTHORITY MERGE SETTINGS
      # -=-=-=-=-=-=-=-=-=-=-

      def assoceventpeople_controlled?
        true if %i[fcart].include?(Tms.cspace_profile)
      end

      # Intermediate fields containing values to be merged into
      #   :assoceventpeople and treated as controlled terms
      setting :assoceventpeople_sources, default: [], reader: true

      def assocpeople_controlled?
        true if %i[fcart].include?(Tms.cspace_profile)
      end

      # Intermediate fields containing values to be merged into
      #   :assoceventpeople
      setting :assocpeople_sources,
        default: [],
        reader: true,
        constructor: ->(_x) do
          return [] unless assocpeople_controlled?

          assocpeople_source_fields.map do |field|
            "#{field}_assocpeople".to_sym
          end
        end

      def contentpeople_controlled?
        true if %i[fcart].include?(Tms.cspace_profile)
      end

      # Intermediate fields containing values to be merged into
      #   :contentpeople
      setting :contentpeople_sources, default: [], reader: true

      def assocplace_controlled?
        true if %i[fcart lhmc].include?(Tms.cspace_profile)
      end

      # @return [Array<Regexp>] used in cleaning/shaping fields that get
      #   extracted to ethnographic_culture authority
      setting :ethculture_uncertainty_patterns, default: [], reader: true

      # If changes are made here, update docs/mapping_options/con_xrefs.adoc as
      #   needed
      setting :con_ref_name_merge_rules,
        default: {
          fcart: {
            objectproduction: {
              suffixes: %w[person organization],
              merge_role: true,
              role_suffix: "role",
              person_note_target: :con_refs_p_objectproductionnote,
              org_note_target: :con_refs_o_objectproductionnote
            },
            assoc: {
              suffixes: %w[person organization],
              merge_role: true,
              role_suffix: "type",
              person_note_target: :assocpersonnote,
              org_note_target: :assocorganizationnote
            },
            content: {
              suffixes: %w[personpersonlocal organizationorganizationlocal],
              merge_role: false,
              person_note_target: :con_refs_p_contentnote,
              org_note_target: :con_refs_o_contentnote
            },
            owner: {
              suffixes: %w[personlocal organizationlocal],
              merge_role: false,
              person_note_target: :con_refs_p_objecthistorynote,
              org_note_target: :con_refs_o_objecthistorynote
            }
          }
        },
        reader: true

      # Custom transform used in :objects__dates. Must be a transform
      #   class without arguments
      setting :date_field_cleaner, default: nil, reader: true
      # Removed in :prep__objects, handled separately in :objects__dates
      setting :date_fields,
        default: %i[dated datebegin dateend beginisodate endisodate],
        reader: true,
        constructor: ->(value) { value - empty_fields.keys }
      # Necessary if :department_target = :dept_namedcollection. Should be a
      #   String value if populated
      setting :department_coll_prefix, default: "", reader: true
      setting :named_coll_fields, default: [], reader: true
      # client-specific transform to clean/alter object number values prior to
      #   doing anything else with Objects table
      setting :number_cleaner, default: nil, reader: true
      setting :record_num_merge_config,
        default: {
          sourcejob: :objects__number_lookup,
          fieldmap: {targetrecord: :objectnumber}
        },
        reader: true
      setting :text_entries_merge_xform, default: nil, reader: true
    end
  end
end
