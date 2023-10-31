# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module ReturnedCompile
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.returned_file_jobs,
                destination: :name_type_cleanup__returned_compile
              },
              transformer: xforms
            )
          end

          def normalizer
            return @normalizer if instance_variable_defined?(:@normalizer)

            @normalizer = Kiba::Extend::Utils::StringNormalizer.new(
              mode: :cspaceid
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              normer = job.send(:normalizer)

              transform config.returned_cleaner if config.returned_cleaner

              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: %i[correctname correctauthoritytype]

              # prepare any migration-added names
              transform do |row|
                name = row[:name]
                type = row[:authoritytype]
                next row unless name.blank? && type.blank?

                corrname = row[:correctname]
                normname = normer.call(corrname)
                corrtype = row[:correctauthoritytype]
                contype = if corrtype == "p"
                  "Person"
                elsif corrtype == "o"
                  "Organization"
                end
                row[:name] = corrname
                row[:authoritytype] = contype
                row[:termsource] = "MigrationAdded"
                nameid = "ma_#{normname}"
                row[:constituentid] = nameid
                row[:cleanupid] = nameid
                row[:prefnormorig] = normname
                row[:namemergenorm] = normname
                row[:contype] = contype
                row[:corrfingerprint] = "#{contype} #{normname}"
                row
              end

              # this can be taken out if we ever do a TMS migration where this
              #   process isn't changing any more during the migration!
              transform do |row|
                next row if row.key?(:cleanupid)

                row[:cleanupid] = "#{row[:constituentid]}_#{row[:name]}"
                row
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[correctname correctauthoritytype constituentid
                  cleanupid],
                target: :combined,
                delete_sources: false,
                delim: " -- "

              transform Deduplicate::Table,
                field: :combined,
                delete_field: true
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
