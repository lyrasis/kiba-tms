# frozen_string_literal: true

module Kiba
  module Tms
    module AltNumsForObjTypeCleanup
      module_function

      extend Dry::Configurable

      setting :base_job,
        default: :alt_nums__types_for_objects,
        reader: true

      setting :fingerprint_fields,
        default: Tms::AltNumsCleanupShared.clean_fingerprint_fields,
        reader: true

      extend Kiba::Extend::Mixins::IterativeCleanup
      extend Tms::AltNumsCleanupShared

      def job_tags
        Tms::AltNumsCleanupShared.cleanup_job_tags(:objects)
      end
    end
  end
end
