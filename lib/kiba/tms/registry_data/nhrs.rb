# frozen_string_literal: true

module Kiba
  module Tms
    module RegistryData
      module Nhrs
        module_function

        def register
          Kiba::Tms.registry.namespace("nhrs") do
            register :object_object, {
              creator: Kiba::Tms::Jobs::Nhrs::ObjectObject,
              path: File.join(
                Kiba::Tms.datadir,
                "ingest",
                "nhr_object_object.csv"
              ),
              tags: %i[nhr collectionobjects ingest]
            }
            register :media_object, {
              creator: Kiba::Tms::Jobs::Nhrs::MediaObject,
              path: File.join(
                Kiba::Tms.datadir,
                "ingest",
                "nhr_media_object.csv"
              ),
              tags: %i[nhr collectionobjects media ingest]
            }
          end
        end
      end
    end
  end
end
