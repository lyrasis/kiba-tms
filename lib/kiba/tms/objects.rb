# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Objects
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[
                    sortnumber textsearchid accountability injurisdiction
                    searchobjectnumber sortsearchnumber
                    usernumber1 usernumber2 usernumber3 usernumber4
                   ],
        reader: true,
        constructor: ->(value){ value + date_fields }
      setting :empty_fields, default: {
        loanclassid: '0',
        objectlevelid: '0',
        objectnameid: '0',
        objectnamealtid: '0',
        objecttypeid: '0',
        publicaccess: '0',
        subclassid: '0',
        type: '0'
      },
        reader: true
      extend Tms::Mixins::Tableable

      setting :annotation_source_fields, default: %i[creditline], reader: true
      setting :annotation_target_fields, default: %i[annotationtype annotationnote], reader: true
      setting :comment_fields,
        reader: true,
        default: %i[comment],
        constructor: ->(default) do
          default << :alt_num_comment if Tms::AltNums.for?('Objects')
          default << :title_comment if Tms::Table::List.include?('ObjTitles')
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
              role_suffix: 'role',
              person_note_target: :con_refs_p_objectproductionnote,
              org_note_target: :con_refs_o_objectproductionnote
            },
            assoc: {
              suffixes: %w[person organization],
              merge_role: true,
              role_suffix: 'type',
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
      setting :contentnote_delim, default: '%CR%%CR%', reader: true
      setting :contentnote_sources,
        default: %i[con_refs_p_contentnote con_refs_o_contentnote],
        reader: true
      # default mapping will be skipped, fields will be left as-is in objects__prep job for handling
      #  in client project
      setting :custom_map_fields, default: [], reader: true
      # will be merged into `Rename::Fields` fieldmap
      setting :custom_rename_fieldmap, default: {}, reader: true
      # necessary if :department_target = :dept_namedcollection. Should be a String value if populated
      # Custom transform used in :objects__dates. Must be a transform
      #   class without arguments
      setting :date_field_cleaner, default: nil, reader: true
      # Removed in :prep__objects, handled separately in :objects__dates
      setting :date_fields,
        default: %i[dated datebegin dateend beginisodate endisodate],
        reader: true,
        constructor: ->(value){ value - empty_fields.keys }
      setting :department_coll_prefix, default: nil, reader: true
      # If setting to :dept_namedcollection, see also the following configs:
      #   department_coll_prefix, named_coll_fields
      # other supported values: :dept_namedcollection
      setting :department_target, default: :responsibledepartment, reader: true
      # Transforms to clean individual fields
      # Elements should be transform classes that do not need to be initialized
      #   with arguments
      setting :field_cleaners, default: [], reader: true
      setting :named_coll_fields, default: [], reader: true
      setting :nontext_inscription_source_fields, default: %i[], reader: true
      setting :nontext_inscription_target_fields, default: %i[], reader: true
      # client-specific transform to clean/alter object number values prior to
      #   doing anything else with Objects table
      setting :number_cleaner, default: nil, reader: true
      setting :objectproductionnote_delim, default: '%CR%%CR%', reader: true
      setting :objectproductionnote_sources,
        default: %i[con_refs_p_objectproductionnote
                    con_refs_o_objectproductionnote],
        reader: true
      setting :objecthistorynote_delim, default: '%CR%%CR%', reader: true
      setting :objecthistorynote_sources,
        default: %i[con_refs_p_objecthistorynote
                    con_refs_o_objecthistorynote],
        reader: true
      setting :period_target, default: nil, reader: true
      setting :record_num_merge_config,
        default: {
          sourcejob: :objects__number_lookup,
          numberfield: :objectnumber
        },
        reader: true
      setting :text_inscription_source_fields, default: %i[signed inscribed markings], reader: true
      setting :text_inscription_target_fields, default: %i[inscriptioncontenttype inscriptioncontent], reader: true
      # TMS fields with associated field-specific transformers defined. Note
      #   these transforms are defined in settings below with the name pattern
      #   `fieldname_xform`
      setting :transformer_fields, default: [], reader: true

      ############
      # Transforms
      ############
      # Configure transformers to transform data in individual source fields or sets of source fields. If nil,
      #   default processing in prep__objects is used unless field is otherwise omitted from processing
      setting :classifications_xform, default: nil, reader: true
      setting :creditline_xform,
        default: Tms::Transforms::DeriveFieldPair.new(
          source: :creditline,
          newfield: :annotationtype,
          value: 'Credit Line',
          sourcebecomes: :annotationnote
        ),
        reader: true
      setting :curatorialremarks_xform,
        default: Kiba::Extend::Transforms::Rename::Field.new(
          from: :curatorialremarks,
          to: :curatorialremarks_comment
        ),
        reader: true
      setting :inscribed_xform,
        default: Tms::Transforms::DeriveFieldPair.new(
          source: :inscribed,
          newfield: :inscriptioncontenttype,
          value: 'inscribed',
          sourcebecomes: :inscriptioncontent
        ),
        reader: true
      setting :markings_xform,
        default: Tms::Transforms::DeriveFieldPair.new(
          source: :markings,
          newfield: :inscriptioncontenttype,
          value: '',
          sourcebecomes: :inscriptioncontent
        ),
        reader: true
      setting :medium_xform, default: nil, reader: true
      setting :signed_xform,
        default: Tms::Transforms::DeriveFieldPair.new(
          source: :signed,
          newfield: :inscriptioncontenttype,
          value: 'signature',
          sourcebecomes: :inscriptioncontent
        ),
        reader: true
      setting :text_entries_merge_xform, default: nil, reader: true
    end
  end
end
