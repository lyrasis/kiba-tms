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
            if config.objectname_controlled
              base << :concept_nomenclature__extract
            end
            # unless Tms::Objects.named_coll_fields.empty?
            #   base << :works__lookup
            # end
            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              if config.objectname_controlled
                transform Merge::MultiRowLookup,
                  lookup: concept_nomenclature__extract,
                  keycolumn: :objectname,
                  fieldmap: {objectnamecontrolled: :preferredform},
                  delim: Tms.delim,
                  multikey: true
                transform Delete::Fields,
                  fields: :objectname
              end

              unless Tms::Objects.named_coll_fields.empty?
                # transform Merge::MultiRowLookup,
                #   lookup: works__lookup,
                #   keycolumn: :,
                #   fieldmap: {},
                #   constantmap: {hash},
                #   conditions: ->(_r, rows)lambdadef,
                #   null_placeholder: "%NULLVALUE%",
                #   delim: ";",
                #   sorter: Lookup::RowSorter.new(
                #     on: :x, dir: :desc, as: :to_i, blanks: :last
                #   ),
                #   multikey: true

              end
            end
          end
        end
      end
    end
  end
end
