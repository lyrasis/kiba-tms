# frozen_string_literal: true

module Kiba
  module Tms
    module RegistryData
      module Names
        module_function

        def register
          Kiba::Tms.registry.namespace("names") do
            register :by_altnameid, {
              desc: "For some bizarre reason, at least some TMS tables link "\
                "to to a name via :constituentid, but the :constituentid "\
                "value should actually be looked up as :altnameid and then "\
                "mapped to correct constituent name. This was discovered "\
                "while mapping valuation control information source "\
                "names.\n\nThis table has the same structure as "\
                ":by_constituentid, but the lookup is on :altnameid",
              creator: Kiba::Tms::Jobs::Names::ByAltnameid,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_by_altnameid.csv"
              ),
              tags: %i[names],
              lookup_on: :altnameid
            }
            register :by_constituentid, {
              creator: Kiba::Tms::Jobs::Names::ByConstituentid,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_by_constituentid.csv"
              ),
              desc: "With lookup on :constituentid, gives :person and :org "\
                "columns from which to merge authorized form of name. Also "\
                "gives :prefname and :nonprefname columns for use if type "\
                "of name does not matter. Only name values are retained in "\
                "this table, not name details.",
              tags: %i[names],
              lookup_on: :constituentid
            }
            register :by_norm, {
              creator: Kiba::Tms::Jobs::Names::ByNorm,
              path: File.join(Kiba::Tms.datadir, "working",
                "names_by_norm.csv"),
              desc: "With lookup on normalized version of original name "\
                "value (i.e. from any table, not controlled by "\
                "constituentid), gives `:person` and `:organization` column "\
                "from which to merge authorized form of name",
              tags: %i[names],
              lookup_on: :norm
            }
            register :by_norm_prep, {
              creator: Kiba::Tms::Jobs::Names::ByNormPrep,
              path: File.join(
                Kiba::Tms.datadir,
                "working",
                "names_by_norm_prep.csv"
              ),
              desc: "Simplifies :name_compile__unique to only normalized "\
                ":contype, :name, and :norm values, where :norm is the "\
                "normalized ORIG value of the name",
              tags: %i[names],
              lookup_on: :norm
            }
          end
        end
      end
    end
  end
end
