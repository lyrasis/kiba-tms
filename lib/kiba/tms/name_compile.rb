# frozen_string_literal: true

module Kiba
  module Tms
    module NameCompile
      module_function

      extend Dry::Configurable
      # Used to auto generate transform jobs for these tables. Key is the config
      #   module for the table, which must implement a :name_fields method and
      #   extend `UncontrolledNameCompilable`. Value is the job key of the
      #   source from which names will be compiled
      setting :uncontrolled_name_source_tables,
        default: {
          "Loans" => :tms__loans,
          "LocApprovers" => :prep__loc_approvers,
          "LocHandlers" => :prep__loc_handlers,
          "ObjAccession" => :tms__obj_accession,
          "ObjIncoming" => :tms__obj_incoming,
          "ObjLocations" => :tms__obj_locations,
          "Packages" => :packages__migrating
        },
        reader: true,
        constructor: proc { |value|
          value.select { |name| Tms.const_get(name).used? }
        }
      setting :sources,
        default: %i[
          name_compile__from_con_person_plain
          name_compile__from_con_org_plain
          name_compile__from_con_org_with_inst
          name_compile__variants_from_duplicate_constituents
          name_compile__from_con_org_with_name_parts
          name_compile__from_con_org_with_single_name_part_no_position
          name_compile__from_con_person_with_inst
          name_compile__from_con_person_with_position_no_inst
          name_compile__from_can_typematch_alt_established
          name_compile__from_can_main_person_alt_org_established
          name_compile__from_can_main_org_alt_person_established
          name_compile__from_can_typematch_variant
          name_compile__from_can_typematch_separate_names
          name_compile__from_can_typematch_separate_notes
          name_compile__from_can_typemismatch_main_person
          name_compile__from_can_typemismatch_main_org
          name_compile__from_can_no_altnametype
          name_compile__from_assoc_parents_for_con
        ],
        reader: true,
        constructor: proc { |value|
          if uncontrolled_name_source_tables.empty?
            value
          else
            value + [:name_compile__from_uncontrolled_name_tables]
          end
        }

      # potential sources not included by default:
      #   name_compile__from_reference_master

      setting :source_treatment,
        default: {
          # options: no other options currently implemented
          name_compile__from_con_org_with_inst: :variant,
          # options: :contact_person, :variant
          name_compile__from_con_org_with_name_parts: :contact_person,
          # options: no other options currently implemented
          name_compile__from_con_org_with_single_name_part_no_position: :variant,
          # options: :contact_person, :variant
          name_compile__from_con_person_with_inst: :contact_person,
          # options: :bio_note, :qualifier, :name_note
          name_compile__from_con_person_with_position_no_inst: :bio_note,
          # options: :bio_note, :name_note, :variant
          name_compile__from_can_typematch_alt_established: :bio_note,
          # options: :contact_person, :bio_note, :name_note, :variant
          name_compile__from_can_main_person_alt_org_established: :contact_person,
          # options: :contact_person, :bio_note, :name_note, :variant
          name_compile__from_can_main_org_alt_person_established: :contact_person,
          # This source always creates a new/separate name for the alt name value.
          #   It also adds a "related name" note for the existing constituent and the new
          #   name. This setting controls which note type the related name note maps to
          # options: :bio_note, :name_note
          name_compile__from_can_typematch_separate: :bio_note,
          # options: :contact_person, :variant
          name_compile__from_can_typemismatch_main_person: :contact_person,
          # options: :contact_person, :variant
          name_compile__from_can_typemismatch_main_org: :contact_person
        },
        reader: true
      # When altname is of same type as main name, altnametype values starting with these values
      #   will be treated as variant terms. Other non-blank altnametype values will be treated
      #   as separate names
      setting :altname_typematch_variant_nametypes,
        default: %w[aka alias alternate birth known label maiden primary],
        reader: true
      # How to handle altnames with same type as main name where there is no altnametype and there
      #   is a :position value
      # options: :separate_name, :variant
      setting :altname_typematch_no_nametype_position, default: :separate_name,
        reader: true
      # How to handle altnames with same type as main name where there is no altnametype and no
      #   :position value
      # options: :separate_name, :variant
      setting :altname_typematch_no_nametype_no_position, default: :variant,
        reader: true

      # fields that should be nil in person records
      setting :person_nil,
        default: %i[institution position],
        reader: true
      # fields that should be nil in org records
      setting :org_nil,
        default: %i[nametitle firstname middlename lastname suffix institution
          position salutation],
        reader: true
      setting :derived_nil,
        default: %i[birth_foundation_date death_dissolution_date datenote biography code nationality
          school remarks culturegroup combined duplicate],
        reader: true
      setting :variant_nil,
        default: [org_nil, person_nil, derived_nil].flatten,
        reader: true
      setting :alt_nil,
        default: %i[conname altname altconname conauthtype altauthtype typematch altnametype altnameconid
          altconauthtype treatment],
        reader: true
      # Used by Services::NameCompile::RelatedNameNoteText
      # Controls values added at beginning/end of parenthethical relator in notes added to names
      #   derived as main names from entries in altname table
      setting :related_name_note_role_prefix_for_alt, default: "", reader: true
      setting :related_name_note_role_suffix_for_alt, default: " of",
        reader: true

      # What categories of terms will be deduplicated in name compilation
      # :main is always deduplicated: contype_norm + normalized form of name
      # :variant: contype_norm + name + variant_term + variant_qualifier should be unique
      # :related: contype_norm + name + relation_type + related_term + related_role should be unique
      # :note: contype_norm + name + relation_type + note_text should be unique
      setting :deduplicate_categories,
        default: %i[variant related note],
        reader: true

      # Indicates whether any cleanup has been returned. If not, we run
      #   everything on base data. If yes, we merge in/overlay cleanup on the
      #   affected base data tables
      setting :done, default: false, reader: true,
        constructor: proc { !returned_files.empty? }
      # List worksheets provided to client, most recent first. Assumes they are
      #   in the client project directory/to_client subdir
      setting :provided_worksheets,
        default: [],
        reader: true,
        constructor: proc { |value|
          value.map do |filename|
            File.join(Kiba::Tms.datadir, "to_client", filename)
          end
        }
      # List returned worksheets, most recent first. Assumes they are in the
      #   client project directory/supplied subdir
      setting :returned_files,
        default: [],
        reader: true,
        constructor: proc { |value|
          value.map do |filename|
            File.join(Kiba::Tms.datadir, "supplied", filename)
          end
        }
      def provided_worksheet_jobs
        provided_worksheets.map.with_index do |filename, idx|
          "name_compile__worksheet_provided_#{idx}".to_sym
        end
      end

      def returned_file_jobs
        returned_files.map.with_index do |filename, idx|
          "name_compile__worksheet_completed_#{idx}".to_sym
        end
      end

      # The section of settings below are used to create the name compile
      #   worksheet and process any changes after it is returned by the client

      def initial_headers
        base = %i[sort authority name relation_type
          variant_term variant_qualifier
          related_term related_role
          note_text] +
          Tms::NameCompile.person_name_detail_fields +
          Tms::NameCompile.main_org_editable
        base.unshift(:to_review) if done
        base
      end

      # String value used to populate fields in name compiled worksheet that
      #   can't be edited/included in migration for a given relation_type
      setting :na_in_migration_value,
        default: "~NA~",
        reader: true
      setting :person_name_detail_fields,
        default: %i[salutation nametitle firstname middlename lastname suffix],
        reader: true
      setting :not_editable_internal,
        default: %i[sort contype name relation_type constituentid prefnormorig
          nonprefnormorig termsource altnorm alttype mainnorm
          namemergenorm],
        reader: true
      setting :main_person_editable,
        reader: true,
        constructor: ->(value) { main_org_editable + person_name_detail_fields }
      setting :main_org_editable,
        default: %i[birth_foundation_date death_dissolution_date datenote
          biography code nationality remarks culturegroup],
        reader: true
      setting :main_person_not_editable,
        default: %i[variant_term variant_qualifier related_term related_role
          note_text],
        reader: true
      setting :main_org_not_editable,
        reader: true,
        constructor: ->(value) {
                       person_name_detail_fields +
                         main_person_not_editable
                     }
      setting :note_editable,
        default: :note_text,
        reader: true
      setting :note_not_editable,
        default: %i[variant_term variant_qualifier related_term related_role],
        reader: true,
        constructor: ->(value) { value + main_person_editable }
      setting :contact_editable,
        default: %i[related_term related_role],
        reader: true
      setting :contact_not_editable,
        default: %i[variant_term variant_qualifier note_text],
        reader: true,
        constructor: ->(value) { value + main_person_editable }
      setting :variant_person_editable,
        reader: true,
        constructor: ->(value) {
                       variant_org_editable + person_name_detail_fields
                     }
      setting :variant_org_editable,
        default: %i[variant_term variant_qualifier],
        reader: true
      setting :variant_person_not_editable,
        default: %i[related_term related_role note_text
          birth_foundation_date death_dissolution_date datenote
          biography code nationality remarks culturegroup],
        reader: true
      setting :variant_org_not_editable,
        reader: true,
        constructor: ->(value) {
                       person_name_detail_fields +
                         variant_person_not_editable
                     }

      # fields to delete from name compilation report
      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields, default: [], reader: true

      def used?
        true
      end

      def register_uncontrolled_name_compile_jobs
        sources = uncontrolled_name_source_tables.keys
        return if sources.empty?

        puts "Registering uncontrolled name compile jobs for "\
          "#{sources.join(", ")}"

        ns = build_registry_namespace(
          "name_compile_from",
          sources.map { |table| Tms.const_get(table) }
        )
        Tms.registry.import(ns)
      end

      def build_registry_namespace(ns_name, tables)
        bind = binding
        Dry::Container::Namespace.new(ns_name) do
          compilemod = bind.receiver
          tables.each do |tablemod|
            params = [compilemod, ns_name, tablemod]
            register tablemod.filekey,
              compilemod.send(:target_job_hash, *params)
          end
        end
      end

      def target_job_hash(compilemod, ns_name, tablemod)
        {
          path: File.join(Tms.datadir,
            "working",
            "#{ns_name}_#{tablemod.filekey}.csv"),
          creator: {callee: Tms::Jobs::NameCompile::ForUncontrolledNameTable,
                    args: {
                      mod: tablemod
                    }},
          tags: %i[name_compile_from]
        }
      end
    end
  end
end
