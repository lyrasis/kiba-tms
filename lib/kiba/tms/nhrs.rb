# frozen_string_literal: true

module Kiba
  module Tms
    module Nhrs
      module_function

      extend Dry::Configurable

      setting :cs_record_id_field,
        default: :objectnumber,
        reader: true

      extend Tms::Mixins::CsTargetable

      def sample_xforms
        bind = binding

        Kiba.job_segment do
          config = bind.receiver

          transform Merge::MultiRowLookup,
            lookup: config.sample_lookup,
            keycolumn: config.cs_record_id_field,
            fieldmap: {insample: config.cs_record_id_field}

          merge_fields = [:insample]

          if Tms::RelsAcqObj.used? && Tms::RelsAcqObj.sampleable?
            transform Merge::MultiRowLookup,
              lookup: Tms.get_lookup(
                jobkey: :rels_acq_obj__for_ingest,
                column: :item2_id
              ),
              keycolumn: :objectnumber,
              fieldmap: {acqobj: :item2_id}
            merge_fields << :acqobj
          end

          transform FilterRows::AnyFieldsPopulated,
            action: :keep,
            fields: merge_fields
          transform Delete::Fields,
            fields: merge_fields
        end
      end
    end
  end
end
