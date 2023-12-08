# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        module AuthoritiesMerged
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :objects__shape,
                destination: :objects__authorities_merged,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            unless config.objectname_controlled_source_fields.empty?
              base << :concept_nomenclature__lookup
            end
            unless config.material_controlled_source_fields.empty?
              base << :concept_material__lookup
            end
            unless config.namedcollection_sources.empty?
              base << :works__lookup
            end
            if config.assocpeople_controlled? &&
                !config.assocpeople_source_fields.empty?
              base << :concept_ethnographic_culture__lookup
            end
            unless config.contentconceptconceptassociated_sources.empty?
              base << :concept_associated__lookup
            end
            base.uniq
              .select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)

              unless config.objectname_controlled_source_fields.empty?
                transform Merge::MultiRowLookup,
                  lookup: concept_nomenclature__lookup,
                  keycolumn: :objectnamecontrolled,
                  fieldmap: {objectnamecontrolled_use: :use},
                  delim: Tms.delim,
                  multikey: true
                transform Delete::Fields,
                  fields: :objectnamecontrolled
                transform Rename::Field,
                  from: :objectnamecontrolled_use,
                  to: :objectnamecontrolled
                grpd = config.objectname_target_fields - [:objectnamecontrolled]
                transform Deduplicate::GroupedFieldValues,
                  on_field: :objectnamecontrolled,
                  grouped_fields: grpd,
                  delim: Tms.delim
                transform Warn::UnevenFields,
                  fields: config.objectname_target_fields
              end

              unless config.material_controlled_source_fields.empty?
                transform Merge::MultiRowLookup,
                  lookup: concept_material__lookup,
                  keycolumn: :materialcontrolled,
                  fieldmap: {materialcontrolled_use: :use},
                  delim: Tms.delim,
                  multikey: true
                transform Delete::Fields,
                  fields: :materialcontrolled
                transform Rename::Field,
                  from: :materialcontrolled_use,
                  to: :materialcontrolled
                grpd = config.material_target_fields - [:materialcontrolled]
                transform Deduplicate::GroupedFieldValues,
                  on_field: :materialcontrolled,
                  grouped_fields: grpd,
                  delim: Tms.delim
                transform Warn::UnevenFields,
                  fields: config.material_target_fields
              end

              unless Tms::Objects.namedcollection_sources.empty?
                transform Merge::MultiRowLookup,
                  lookup: works__lookup,
                  keycolumn: :namedcollection_raw,
                  fieldmap: {namedcollection: :use},
                  multikey: true
                transform Delete::Fields,
                  fields: :namedcollection_raw
              end

              if config.assocpeople_controlled? &&
                  !config.assocpeople_source_fields.empty?
                transform Merge::MultiRowLookup,
                  lookup: concept_ethnographic_culture__lookup,
                  keycolumn: :assocpeople,
                  fieldmap: {assocpeople_use: :use},
                  multikey: true
                transform Delete::Fields,
                  fields: :assocpeople
                transform Rename::Field,
                  from: :assocpeople_use,
                  to: :assocpeople
                transform Deduplicate::GroupedFieldValues,
                  on_field: :assocpeople,
                  grouped_fields: %i[assocpeopletype assocpeoplenote],
                  delim: Tms.delim
              end

              if config.assocplace_controlled? &&
                  !config.assocplace_source_fields.empty?
                transform Merge::MultiRowLookup,
                  lookup: config.place_authority_lookup,
                  keycolumn: :assocplace,
                  fieldmap: {assocplace_use: :use},
                  multikey: true
                transform Delete::Fields,
                  fields: :assocplace
                transform Rename::Field,
                  from: :assocplace_use,
                  to: :assocplace
                transform Deduplicate::GroupedFieldValues,
                  on_field: :assocplace,
                  grouped_fields: %i[assocplacetype assocplacenote],
                  delim: Tms.delim
              end

              unless config.contentconceptconceptassociated_sources.empty?
                transform Merge::MultiRowLookup,
                  lookup: concept_associated__lookup,
                  keycolumn: :contentconceptconceptassociated,
                  fieldmap: {cass_use: :use},
                  multikey: true
                transform Delete::Fields,
                  fields: :contentconceptconceptassociated
                transform Rename::Field,
                  from: :cass_use,
                  to: :contentconceptconceptassociated
                transform Deduplicate::FieldValues,
                  fields: :contentconceptconceptassociated,
                  sep: Tms.delim
              end
            end
          end
        end
      end
    end
  end
end
