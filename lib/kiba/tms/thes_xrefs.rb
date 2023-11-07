# frozen_string_literal: true

module Kiba
  module Tms
    module ThesXrefs
      extend Dry::Configurable

      module_function

      # As with ObjLocations, it appears that inactive here is a way to mark
      #   erroneous/accidental entries
      setting :drop_inactive, default: true, reader: true

      # Treatment applied to rows for merge into Constituents when
      #   :thesxreftype is blank
      setting :for_constituents_untyped_default_treatment,
        default: :plain_note,
        reader: true

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[removedloginid removeddate],
        reader: true
      extend Tms::Mixins::Tableable

      setting :type_field, default: :thesxreftype, reader: true
      setting :note_field, default: :remarks, reader: true
      setting :mergeable_value_field, default: :termused, reader: true
      setting :additional_occurrence_ct_fields,
        default: %i[remarks],
        reader: true
      extend Tms::Mixins::MultiTableMergeable

      # Mappings for :thesxreftableid field values. Listed in data dictionary
      #   as TableIDs for the ThesXrefs Physical Table
      setting :table_aliases, default: {
                                "343" => "Attributes",
                                "346" => "Geography",
                                "358" => "Statuses",
                                "361" => "Locations",
                                "469" => "StatusInact",
                                "604" => "GeoInact",
                                "650" => "AttrInact"
                              },
        reader: true

      # The `treatments_used` settings below are client-specific and should be
      #   populated after completion of type_cleanup_worksheet for each target
      #   table. They control what post-processing of merged data needs to be
      #   done after initial processing/merge into intermediate fields is done.
      setting :constituents_treatments_used, default: %i[], reader: true
      setting :objects_treatments_used, default: %i[], reader: true

      # the `note_suffixes` settings below are client-specific and should be
      #   populated after completion of type_cleanup_worksheet for each target
      #   table. They are used to derive and add full note field names to the
      #   note source settings for post-processing.
      setting :constituents_note_suffixes,
        default: {internal: [], public: []},
        reader: true
      setting :objects_note_suffixes,
        default: {internal: [], public: []},
        reader: true

      # @param table [String] the target table name
      # @param type [:internal, :public]
      def note_source_fields(table:, type:)
        treatments = "#{table.downcase}_treatments_used".to_sym
        basefieldname = "type_labeled_#{type}_note".to_sym
        return [] unless send(treatments).include?(basefieldname)

        base = basefieldname.to_s.sub("type_labeled", "term")
        send("#{table.downcase}_note_suffixes".to_sym)[type].map do |suffix|
          "#{base}_#{suffix}".to_sym
        end
      end

      # The `removable terms` settings below indicate terms that will be
      #   removed from type_labeled_*_note_* treatment values merged into
      #   target data. For instance, when term = "see remarks", and the note is
      #   is going to include the remarks, we can omit term "see remarks"
      setting :constituents_omit_terms, default: %w[], reader: true
      setting :objects_omit_terms, default: %w[], reader: true

      # pass in client-specific transform classes to prepare thes_xrefs rows for
      #   merging
      setting :for_loans_prepper, default: nil, reader: true

      # pass in client-specific transform classes to merge thes_xrefs rows into
      #   target tables
      setting :for_loans_merge, default: nil, reader: true

      def set_note_sources
        if for?("Constituents")
          set_org_sources
          set_person_sources
        end
      end

      def set_org_sources
        note_source_fields(
          table: "Constituents", type: :public
        ).each { |field| Tms::Orgs.historynote_sources << field }
        %i[term_note_nationality term_note_foundingplace
          term_note_dissolutionplace term_plain_note
          term_note_gender].each do |field|
          Tms::Orgs.historynote_sources << field
        end
        note_source_fields(
          table: "Constituents", type: :internal
        ).each { |field| Tms::Orgs.historynote_sources << field }
      end
      private_class_method :set_org_sources

      def set_person_sources
        note_source_fields(
          table: "Constituents", type: :public
        ).each { |field| Tms::Persons.bionote_sources << field }
        %i[term_note_nationality term_note_birthplace
          term_note_deathplace term_note_gender].each do |field|
          Tms::Persons.bionote_sources << field
        end
        note_source_fields(
          table: "Constituents", type: :internal
        ).each { |field| Tms::Persons.namenote_sources << field }
        Tms::Persons.namenote_sources << :term_plain_note
      end
      private_class_method :set_person_sources
    end
  end
end
