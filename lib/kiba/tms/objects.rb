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
          usernumber1 usernumber2 usernumber3 usernumber4
          istemplate isvirtual
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

      # @return [#process] custom transform to handle merged-in classifications
      #   fields
      setting :classifications_shape_xform, default: nil, reader: true

      # @return [Array<#process>] run in order at the end of
      #   :objects__shape job
      setting :post_shape_xforms, default: [], reader: true
      # -----------------------------------------------------------------------
      # Default field-specific transforms
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
      setting :curatorapproved_xform,
        default: {Tms::Transforms::Objects::Curatorapproved =>
                  {positivestatus: "curator approved"}},
        reader: true
      setting :curatorialremarks_xform,
        default: {
          Rename::Field => {
            from: :curatorialremarks,
            to: :curatorialremarks_comment
          }
        },
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

      # @return [Hash{Symbol=>Symbol}]
      setting :base_field_rename_map,
        default: {
          chat: :viewerscontributionnote,
          culture: :objectproductionpeople,
          description: :briefdescription,
          medium: :materialtechniquedescription,
          notes: :comment,
          objectcount: :numberofobjects
        },
        reader: true,
        constructor: ->(default) do
          return default if dimensions_to_merge?

          default.merge({dimensions: :dimensionsummary})
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
        constructor: ->(default) do
          if Tms::AltNums.for_objects_annotation_treatments_used
            default << :altnum
          end
          default
        end
      setting :annotation_target_fields,
        default: %i[annotationtype annotationnote],
        reader: true
      setting :nontext_inscription_source_fields, default: %i[], reader: true
      setting :nontext_inscription_target_fields, default: %i[], reader: true
      setting :text_inscription_source_fields,
        default: %i[signed inscribed markings],
        reader: true
      setting :text_inscription_target_fields,
        default: %i[inscriptioncontenttype inscriptioncontent],
        reader: true

      # Intermediate fields containing values to be merged into `comments`
      #   field
      #
      # @return [Array<Symbol]
      setting :comment_fields,
        reader: true,
        default: %i[comment],
        constructor: ->(default) do
          default << :alt_num_comment if Tms::AltNums.for?("Objects")
          default << :title_comment if Tms::Table::List.include?("ObjTitles")
          default
        end

      # Intermediate fields containing values to be merged into
      #   `inventoryStatus` field
      #
      # @return [Array<Symbol]
      setting :status_source_fields,
        default: [],
        reader: true,
        constructor: ->(default) do
          default << :main_objectstatus if Tms::ObjectStatuses.used?
          default << :linkedset_objectstatus if Tms::LinkedSetAcq.used?
          default
        end

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

      setting :contentnote_delim, default: Tms.notedelim, reader: true
      setting :contentnote_sources,
        default: %i[con_refs_p_contentnote con_refs_o_contentnote],
        reader: true
      # Default mapping will be skipped, fields will be left as-is for handling
      #   in client project
      setting :custom_map_fields, default: [], reader: true
      # will be merged into :base_field_rename_map
      setting :custom_rename_fieldmap, default: {}, reader: true
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
      setting :department_coll_prefix, default: nil, reader: true
      # If setting to :dept_namedcollection, see also the following configs:
      #   department_coll_prefix, named_coll_fields
      # other supported values: :dept_namedcollection
      setting :named_coll_fields, default: [], reader: true
      # client-specific transform to clean/alter object number values prior to
      #   doing anything else with Objects table
      setting :number_cleaner, default: nil, reader: true
      setting :objectproductionnote_delim, default: Tms.notedelim, reader: true
      setting :objectproductionnote_sources,
        default: %i[con_refs_p_objectproductionnote
          con_refs_o_objectproductionnote],
        reader: true
      setting :objecthistorynote_delim, default: Tms.notedelim, reader: true
      setting :objecthistorynote_sources,
        default: %i[con_refs_p_objecthistorynote
          con_refs_o_objecthistorynote],
        reader: true
      setting :period_target, default: nil, reader: true
      setting :record_num_merge_config,
        default: {
          sourcejob: :objects__number_lookup,
          fieldmap: {targetrecord: :objectnumber}
        },
        reader: true
      setting :text_entries_merge_xform, default: nil, reader: true

      def rename_map
        tmp = {}
        custom = custom_map_fields
        base_field_rename_map.each do |from, to|
          tmp[from] = to unless custom.include?(from)
        end
        tmp.merge(custom_rename_fieldmap)
      end
    end
  end
end
