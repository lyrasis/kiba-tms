# frozen_string_literal: true

# Mixin module providing consistent methods for config modules that
#   represent CollectionSpace nonhierarchical relationships
#
# ## Implementation details
#
# Modules mixing this in must:
#
# - `extend Tms::Mixins::CsNonhierarchicalRelation`
#
# This module should be mixed in AFTER any other mixins
module Kiba
  module Tms
    module Mixins
      module CsNonhierarchicalRelation
        def self.extended(mod)
          define_used_method(mod)
        end

        def sampleable?
          return false if Tms.migration_status == :prod

          used? && respond_to?(:sample_from) && sample_mod.sampleable?
        end

        def sample_mod
          Tms.const_get(send(send(:sample_from)))
        rescue NameError
          nil
        end

        def sample_job_key
          sample_mod.sample_job_key
        end

        def sample_lookup
          Tms.get_lookup(
            jobkey: sample_job_key,
            column: sample_mod.cs_record_id_field
          )
        end

        def sample_id_field
          return :item1_id if sample_from == :rectype1

          :item2_id
        end

        def sample_xforms
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

        def self.define_used_method(mod)
          return if mod.respond_to?(:used?)

          str = <<~CFG
            def used?
              Tms.cspace_target_records.include?(rectype1) &&
                Tms.cspace_target_records.include?(rectype2)
            end
          CFG

          mod.instance_eval(str, __FILE__, __LINE__)
        end
      end
    end
  end
end
