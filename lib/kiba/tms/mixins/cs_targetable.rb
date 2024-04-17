# frozen_string_literal: true

# Mixin module providing consistent methods for config modules that
#   represent CollectionSpace target record types
#
# ## Implementation details
#
# Modules mixing this in must:
#
# - `extend Tms::Mixins::CsTargetable`
#
# This module should be mixed in AFTER any other mixins
#
# The main reason for using this mixin is to enable semi-auto handling of
# record samples in prod. For this use, you must define the following
# before extending with this module:
#
# - :cs_record_id_field
module Kiba
  module Tms
    module Mixins
      module CsTargetable
        def self.extended(mod)
          define_used_method(mod)
        end

        def sampleable?
          return false if Tms.migration_status == :prod
          return false unless respond_to?(:cs_record_id_field)

          Tms.registry.key?(sample_job_key)
        end

        def sample_job_key
          rectype = name.to_s
            .split("::")
            .last
            .downcase
          "sample__#{rectype}".to_sym
        end

        def sample_lookup
          Tms.get_lookup(
            jobkey: sample_job_key,
            column: cs_record_id_field
          )
        end

        def sample_xforms
          bind = binding

          Kiba.job_segment do
            config = bind.receiver

            transform Merge::MultiRowLookup,
              lookup: config.sample_lookup,
              keycolumn: config.cs_record_id_field,
              fieldmap: {insample: config.cs_record_id_field}
            transform FilterRows::FieldPopulated,
              action: :keep,
              field: :insample
            transform Delete::Fields,
              fields: :insample
          end
        end

        def self.define_used_method(mod)
          return if mod.respond_to?(:used?)

          str = <<~CFG
            def used?
              Tms.cspace_target_records.include?(
                name.delete_prefix("Kiba::Tms::")
              )
            end
          CFG

          mod.instance_eval(str, __FILE__, __LINE__)
        end
      end
    end
  end
end
