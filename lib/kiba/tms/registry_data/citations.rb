# frozen_string_literal: true

module Kiba
  module Tms
    module RegistryData
      module Citations
        module_function

        def register
          Tms.registry.namespace("citations") do
            register :preload, {
              creator: Kiba::Tms::Jobs::Citations::Preload,
              path: File.join(Kiba::Tms.datadir, "ingest",
                "citations_preload.csv"),
              desc: "The citations needed to populate termsourcecitationlocal "\
                "with journal or series titles. Need to be loaded before the "\
                "rest of the citation record can be loaded",
              tags: %i[reference_master citations ingest]
            }
            register :main, {
              creator: Kiba::Tms::Jobs::Citations::Main,
              path: File.join(Kiba::Tms.datadir, "ingest",
                "citations_main.csv"),
              desc: "The main citations ingest",
              tags: %i[reference_master citations ingest],
              dest_special_opts: {initial_headers: %i[termdisplayname]}
            }
            register :pubdate, {
              creator: Kiba::Tms::Jobs::Citations::Pubdate,
              path: File.join(Kiba::Tms.datadir, "ingest",
                "citations_pubdate.csv"),
              desc: "Structured date details to be loaded after all citations "\
                "are ingested",
              tags: %i[reference_master citations dates ingest]
            }
            register :lookup, {
              creator: Kiba::Tms::Jobs::Citations::Lookup,
              path: File.join(Kiba::Tms.datadir, "working",
                "citations_lookup.csv"),
              tags: %i[reference_master citations ingest],
              lookup_on: :norm
            }
          end
        end
      end
    end
  end
end
