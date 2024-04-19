# frozen_string_literal: true

module Kiba
  module Tms
    module Nhrs
      module_function

      extend Dry::Configurable

      # @return [String, nil] name of CsTargetable-extending config module. Set
      #   from job
      setting :rectype1,
        default: nil,
        reader: true

      # @return [String, nil] name of CsTargetable-extending config module. Set
      #   from job
      setting :rectype2,
        default: nil,
        reader: true

      setting :job_xforms, default: nil, reader: true

      def transformers
        [job_xforms, sample_xforms, config_finalize_xforms].flatten
          .compact
      end

      # @return [:rectype1, :rectype2, nil] Set from job if intending to output
      #   a sample set of relations
      setting :sample_from,
        default: nil,
        reader: true

      def sampleable?
        return false if Tms.migration_status == :prod

        sample_from && used? && sample_mod.sampleable?
      end

      def used?
        Tms.cspace_target_records.include?(rectype1) &&
          Tms.cspace_target_records.include?(rectype2)
      end

      def sample_mod
        Tms.const_get(send(send(:sample_from)))
      rescue NameError
        nil
      end

      def sample_id_field
        return :item1_id if sample_from == :rectype1

        :item2_id
      end

      def sample_job_key = sample_mod.sample_job_key

      def sample_lookup
        Tms.get_lookup(
          jobkey: sample_job_key,
          column: sample_mod.cs_record_id_field
        )
      end

      def sample_xforms
        return nil unless sampleable?

        bind = binding

        Kiba.job_segment do
          config = bind.receiver

          transform Merge::MultiRowLookup,
            lookup: config.sample_lookup,
            keycolumn: config.sample_id_field,
            fieldmap: {insample: config.sample_mod.cs_record_id_field}
          transform FilterRows::FieldPopulated,
            action: :keep,
            field: :insample
          transform Delete::Fields,
            fields: :insample
        end
      end

      def finalize_xforms
        Kiba.job_segment do
          transform FilterRows::AllFieldsPopulated,
            action: :keep,
            fields: %i[item1_id item2_id]
          transform CombineValues::FullRecord, delim: " "
          transform Deduplicate::Table,
            field: :index,
            delete_field: true
        end
      end

      def config_finalize_xforms
        bind = binding

        Kiba.job_segment do
          config = bind.receiver

          transform FilterRows::AllFieldsPopulated,
            action: :keep,
            fields: %i[item1_id item2_id]
          transform CombineValues::FullRecord, delim: " "
          transform Deduplicate::Table,
            field: :index,
            delete_field: true
          transform Merge::ConstantValues,
            constantmap: {
              item1_type: config.send(:rectype1).downcase,
              item2_type: config.send(:rectype2).downcase
            }
        end
      end
    end
  end
end
