# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        # Person and Organization authorities do not need to be looked up/merged
        #   because authorized form of those names were merged in initially
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
            if config.assocpeople_controlled? &&
                !config.assocpeople_source_fields.empty?
              base << :concept_ethnographic_culture__lookup
            end
            unless config.contentconceptconceptassociated_sources.empty?
              base << :concept_associated__lookup
            end
            unless config.contenteventchronologyera_sources.empty?
              base << :chronology_era__lookup
            end
            unless config.contenteventchronologyevent_sources.empty?
              base << :chronology_event__lookup
            end
            if config.contentpeople_controlled? &&
                !config.contentpeople_sources.empty?
              base << :concept_ethnographic_culture__lookup
            end
            unless config.materialcontrolled_source_fields.empty?
              base << :concept_material__lookup
            end
            unless config.namedcollection_sources.empty?
              base << :works__lookup
            end
            unless config.objectnamecontrolled_source_fields.empty?
              base << :concept_nomenclature__lookup
            end
            base.uniq
              .select { |job| Kiba::Extend::Job.output?(job) }
          end

          def get_lookup(field)
            dict[field]
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)

              lookup_by_field = {
                assocpeople: -> do
                               send(:concept_ethnographic_culture__lookup)
                             end,
                assocplace: -> { config.place_authority_lookup },
                contentconceptconceptassociated: -> do
                                                   send(:concept_associated__lookup)
                                                 end,
                contenteventchronologyera: -> { send(:chronology_era__lookup) },
                contenteventchronologyevent: -> do
                  send(:chronology_event__lookup)
                end,
                contentpeople: -> do
                                 send(:concept_ethnographic_culture__lookup)
                               end,
                materialcontrolled: -> { send(:concept_material__lookup) },
                namedcollection: -> { send(:works__lookup) },
                objectnamecontrolled: -> { send(:concept_nomenclature__lookup) }
              }

              # Terms in repeatable field groups configured for deduplication
              %i[assocpeople assocplace materialcontrolled
                objectnamecontrolled].each do |field|
                contmeth = "#{field}_controlled?".to_sym
                next if config.respond_to?(contmeth) &&
                  !config.send(contmeth)

                source_fields = config.send("#{field}_source_fields".to_sym)
                merged_field = "#{field}_use".to_sym
                grouplabel = case field.to_s.end_with?("controlled")
                when true
                  field.to_s.sub("controlled", "").to_sym
                else
                  field
                end
                main_field = config.send("#{grouplabel}_main_field".to_sym)
                grpd_fields = config.send("#{grouplabel}_grouped_fields".to_sym)

                unless source_fields.empty?
                  transform Merge::MultiRowLookup,
                    lookup: lookup_by_field[field].call,
                    keycolumn: field,
                    fieldmap: {merged_field => :use},
                    multikey: true
                  transform Delete::Fields,
                    fields: field
                  transform Rename::Field,
                    from: merged_field,
                    to: field
                  transform Deduplicate::GroupedFieldValues,
                    on_field: main_field,
                    grouped_fields: grpd_fields,
                    delim: Tms.delim
                end
              end

              # Terms in repeatable fields
              %i[
                contentconceptconceptassociated
                contenteventchronologyera
                contenteventchronologyevent
                contentpeople
                namedcollection
              ].each do |field|
                sources = config.send("#{field}_sources".to_sym)
                orig_field = "#{field}_raw".to_sym

                unless sources.empty?
                  transform Merge::MultiRowLookup,
                    lookup: lookup_by_field[field].call,
                    keycolumn: orig_field,
                    fieldmap: {field => :use},
                    multikey: true
                  transform Delete::Fields,
                    fields: orig_field
                  transform Deduplicate::FieldValues,
                    fields: field,
                    sep: Tms.delim
                end
              end
            end
          end
        end
      end
    end
  end
end
