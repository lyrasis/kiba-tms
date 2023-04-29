# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Exhibitions
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__exhibitions,
                destination: :prep__exhibitions,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = [:locs__compiled_clean]
            if Tms::Departments.used?
              base << :prep__departments
            end
            if Tms::ExhibitionStatuses.used?
              base << :prep__exhibition_statuses
            end
            if Tms::ExhibitionTitles.used?
              base << :prep__exhibition_titles
            end
            if Tms::ExhVenuesXrefs.used?
              base << :prep__exh_venues_xrefs
            end
            base.select{ |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields,
                  fields: config.omitted_fields
              end
              transform Tms.data_cleaner if Tms.data_cleaner

              if lookups.any?(:prep__departments)
                transform Merge::MultiRowLookup,
                  lookup: prep__departments,
                  keycolumn: :exhdepartment,
                  fieldmap: {department: :department},
                  delim: Tms.delim
              end
              transform Delete::Fields, fields: :exhdepartment

              if lookups.any?(:prep__exhibition_statuses)
                transform Merge::MultiRowLookup,
                  lookup: prep__exhibition_statuses,
                  keycolumn: Tms::ExhibitionStatuses.id_field,
                  fieldmap: {status: Tms::ExhibitionStatuses.type_field}
              end
              transform Delete::Fields,
                fields: Tms::ExhibitionStatuses.id_field

              if lookups.any?(:prep__exhibition_titles)
                transform Merge::MultiRowLookup,
                  lookup: prep__exhibition_titles,
                  keycolumn: :exhibitionid,
                  fieldmap: {othertitle: :title},
                  delim: "%CR%"
              end

              if config.fields.any?(:locationid)
                transform Append::ToFieldValue,
                  field: :locationid,
                  value: "|nil"
                transform Merge::MultiRowLookup,
                  lookup: locs__compiled_clean,
                  keycolumn: :locationid,
                  fieldmap: {
                    locationname: :location_name,
                    locationauth: :storage_location_authority
                  },
                  delim: Tms.delim
                transform Delete::Fields, fields: :locationid
              end

              if lookups.any?(:prep__exh_venues_xrefs)
                transform Merge::MultiRowLookup,
                  lookup: prep__exh_venues_xrefs,
                  keycolumn: :exhibitionid,
                  fieldmap: {
                    venue_xref_org: :venueorg,
                    venue_xref_open_date: :beginisodate,
                    venue_xref_close_date: :endisodate
                  },
                  sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i),
                  null_placeholder: Tms.nullvalue,
                  delim: Tms.delim
                transform Merge::MultiRowLookup,
                  lookup: prep__exh_venues_xrefs,
                  keycolumn: :exhibitionid,
                  fieldmap: {insindnote: :insindnote},
                  sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i),
                  null_placeholder: Tms.nullvalue,
                  delim: "%CR%%CR%"
                transform Delete::EmptyFieldValues,
                  fields: :insindnote,
                  delim: "%CR%%CR%",
                  usenull: true
              end

              # populates person and org names from ConXrefs
              if Tms::ConRefs.for?("Exhibitions")
                if config.con_ref_name_merge_rules
                  transform Tms::Transforms::ConRefs::Merger,
                    into: config,
                    keycolumn: :exhibitionid
                end
              end

              if Tms::TextEntries.for?("Exhibitions")
                xform = Tms::TextEntries.for_exhibitions_merge
                transform xform if xform
              end

              transform Merge::ConstantValue,
                target: :pre, value: "EXH"
              transform Tms::Transforms::IdGenerator,
                id_source: :pre,
                id_target: :exhibitionnumber,
                sort_on: :exhibitionid,
                sort_type: :i,
                separator: "",
                padding: 4
            end
          end
        end
      end
    end
  end
end
