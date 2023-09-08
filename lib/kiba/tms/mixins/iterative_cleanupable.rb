# frozen_string_literal: true

# Mixin module for setting up iterative cleanup based on a source table.
#
# "Iterative cleanup" means the client may provide the worksheet more
#   than once, or that you may need to produce a fresh worksheet for
#   the client after a new database export is provided.
#
# ## What extending this module does
#
#
# ## Implementation details
#
# Modules mixing this in must do the following before extending this module:
#
# - define `:source_job_key` for the table, if it is not a TMS base table.
#   (Most cleanup is NOT based on the raw TMS table, so you will certainly need
#   to define this
# - OPTIONALLY, set `:delete_fields` setting. Only set this if you want to be
#   able to use `Delete::Fields, fields: config.omitted_fields` in your
#   cleanup worksheet prep job
# - OPTIONALLY, set `:non_content_fields` setting. Only set this if you want to
#   be able to use content_fields or non_content_fields as values for
#   transforms in your cleanup worksheet prep job
#
# The above must be defined before extending this module, because this module
#   will also extend `Tableable`
#
# - `extend Tms::Mixins::IterativeCleanupable`
module Kiba::Tms::Mixins::IterativeCleanupable
  def self.extended(mod)
    check_source_job_key(mod)
    mod.extend(Tms::Mixins::Tableable)
  end

  def self.check_source_job_key(mod)
    unless mod.respond_to?(:source_job_key)
      raise Tms::SourceJobKeyUndefinedError
    end
  end
  private_class_method :check_source_job_key
end
