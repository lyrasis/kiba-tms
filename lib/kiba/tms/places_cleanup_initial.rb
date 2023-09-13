# frozen_string_literal: true

# Config module setting up initial place cleanup. This module should
#   NOT necessarily be used as a model for setting up
#   IterativeCleanupable. It was converted to use the mixin as a
#   proof-of-concept that the mixin approach could handle a high level
#   of weird custom stuff. In particular, the custom pre/post transforms
#   defined are way over-complicated, to keep from having to completely rebuild
#   the test data set for place cleanup.
module Kiba::Tms::PlacesCleanupInitial
  extend Dry::Configurable

  module_function

  setting :base_job,
    default: :places__norm_unique,
    reader: true

  def fingerprint_fields
    Tms::Places.source_fields
  end

  extend Kiba::Extend::Mixins::IterativeCleanup

  def orig_values_identifier
    :norm_fingerprint
  end

  def job_tags
    %i[places cleanup]
  end

  def worksheet_add_fields
    Tms::Places.worksheet_added_fields
  end

  def worksheet_field_order
    base = []
    base << Tms::Places.hierarchy_fields.reverse
    base << (Tms::Places.source_fields - Tms::Places.hierarchy_fields)
    base << Tms::Places.worksheet_added_fields
    base << %i[occurrences norm_combineds norm_fingerprints
      clean_fingerprint]
    base.flatten.uniq
  end

  def collate_fields
    %i[norm_combined fingerprint occurrences]
  end

  def base_job_cleaned_pre_xforms
    Kiba.job_segment do
      transform Copy::Field,
        from: :norm_fingerprint,
        to: :fingerprint
    end
  end

  def base_job_cleaned_post_xforms
    bind = binding

    Kiba.job_segment do
      mod = bind.receiver

      transform CombineValues::FromFieldsWithDelimiter,
        sources: mod.fingerprint_fields,
        target: :clean_combined,
        delim: "|||",
        prepend_source_field_name: true,
        delete_sources: false
    end
  end

  def cleaned_uniq_post_xforms
    bind = binding

    Kiba.job_segment do
      mod = bind.receiver

      transform Tms::Transforms::SumCollatedOccurrences,
        field: :occurrences,
        delim: mod.collation_delim
    end
  end

  def corrections_post_xforms
    Kiba.job_segment do
      transform Delete::Fields,
        fields: %i[occurrences norm_combineds clean_combined clean_fingerprint]
    end
  end

  def final_post_xforms
    Kiba.job_segment do
      transform Delete::Fields,
        fields: :fingerprint
    end
  end
end
