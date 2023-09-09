# frozen_string_literal: true

# Mixin module for setting up iterative cleanup based on a source table.
#
# "Iterative cleanup" means the client may provide the worksheet more
#   than once, or that you may need to produce a fresh worksheet for
#   the client after a new database export is provided.
#
# Refer to the AltNumsForObjTypeCleanup as an example config module
#   extending this mixin module.
#
# ## Implementation details
#
# Modules mixing this in must do the following before extending this module:
#
# - Define `:cleanup_base_name` setting. String. Will be
#
# Then:
#
# - `extend Tms::Mixins::IterativeCleanupable`
#
# ## What extending this module does
#
# ### Defines settings in the extending config module
#
# These are empty settings with constructors that will use the values in a
#   client-specific project config file to build the data expected for cleanup
#   processing
#
# #### :provided_worksheets
#
# Array of filenames of cleanup worksheets provided to the client.
#   Files should be listed oldest-to-newest. Assumes files are in the
#   `to_client` subdirectory of the migration base directory.
#
# Define actual values in client config file.
#
# #### :returned_files
#
# Array of filenames of completed worksheets returned by client. Files should be
#   listed oldest-to-newest. Assumes files are in the `supplied` subdirectory
#   of the migration base directory
#
# Define actual values in client config file.
#
# ### Defines methods in the extending config module
#
# See method documentation inline below.
#
module Kiba::Tms::Mixins::IterativeCleanupable
  def self.extended(mod)
    check_required_settings(mod)
    define_provided_worksheets_setting(mod)
    define_returned_files_setting(mod)
  end

  # @return [Array<Symbol>] supplied registry entry job keys corresponding to
  #   provided worksheet files
  def provided_worksheet_jobs
    provided_worksheets.map.with_index do |filename, idx|
      "#{cleanup_base_name}__worksheet_provided_#{idx}".to_sym
    end
  end

  # @return [Array<Symbol>] supplied registry entry job keys corresponding to
  #   returned cleanup files
  def returned_file_jobs
    returned_files.map.with_index do |filename, idx|
      "#{cleanup_base_name}__file_returned_#{idx}".to_sym
    end
  end

  # @return [Boolean]
  def cleanup_done?
    true unless returned_files.empty?
  end
  alias_method :cleanup_done, :cleanup_done?

  # @return [Boolean]
  def worksheet_sent_not_done?
    true if !cleanup_done? && !provided_worksheets.empty?
  end

  # @return [Symbol] the registry entry job key for the base job with cleanup
  #   merged in
  def base_job_cleaned_job_key
    "#{cleanup_base_name}__base_job_cleaned".to_sym
  end

  # @return [Symbol] the registry entry job key for the worksheet prep job
  def worksheet_job_key
    "#{cleanup_base_name}__worksheet".to_sym
  end

  # @return [Symbol] the registry entry job key for the compiled corrections job
  def corrections_job_key
    "#{cleanup_base_name}__corrections".to_sym
  end

  def self.check_required_settings(mod)
    %i[cleanup_base_name base_job job_tags worksheet_add_fields
      worksheet_field_order fingerprint_fields
      fingerprint_flag_ignore_fields].each do |setting|
      unless mod.respond_to?(setting)
        raise Tms::SettingUndefinedError, setting
      end
    end
  end
  private_class_method :check_required_settings

  def self.define_provided_worksheets_setting(mod)
    provided_worksheets = <<~CODE
      # Filenames of cleanup worksheets provided to the client. Should be
      #   ordered oldest-to-newest. Assumes files are in the `to_client`
      #   subdirectory of the migration base directory
      #
      # @return Array<String>
      setting :provided_worksheets,
        default: [],
        reader: true,
        constructor: proc { |value|
          value.map do |filename|
            File.join(Kiba::Tms.datadir, "to_client", filename)
          end
        }
    CODE
    mod.module_eval(provided_worksheets, __FILE__, __LINE__)
  end
  private_class_method :define_provided_worksheets_setting

  def self.define_returned_files_setting(mod)
    returned_files = <<~CODE
      # Filenames cleanup worksheets provided to the client. Should be ordered
      #   oldest-to-newest. Assumes files are in the `to_client` subdirectory
      #   of the migration base directory
      #
      # @return Array<String>
      setting :returned_files,
        default: [],
        reader: true,
        constructor: proc { |value|
          value.map do |filename|
            File.join(Kiba::Tms.datadir, "to_client", filename)
          end
        }
    CODE
    mod.module_eval(returned_files, __FILE__, __LINE__)
  end
  private_class_method :define_returned_files_setting

  def register_cleanup_jobs
    ns = build_namespace
    Tms.registry.import(ns)
  end

  def build_namespace
    bind = binding

    Dry::Container::Namespace.new(cleanup_base_name) do
      mod = bind.receiver
      register :base_job_cleaned,
        mod.send(:base_job_cleaned_job_hash, mod)
      register :worksheet, mod.send(:worksheet_job_hash, mod)
    end
  end
  private :build_namespace

  def base_job_cleaned_job_hash(mod)
    {
      path: File.join(Tms.datadir, "working",
        "#{mod.cleanup_base_name}_base_job_cleaned.csv"),
      creator: {
        callee: Tms::Jobs::IterativeCleanup::BaseJobCleaned,
        args: {mod: mod}
      },
      tags: mod.job_tags
    }
  end
  private :base_job_cleaned_job_hash

  def worksheet_job_hash(mod)
    {
      path: File.join(Tms.datadir, "to_client",
        "#{mod.cleanup_base_name}_worksheet.csv"),
      creator: {
        callee: Tms::Jobs::IterativeCleanup::Worksheet,
        args: {mod: mod}
      },
      tags: mod.job_tags,
      dest_special_opts: {initial_headers: mod.worksheet_field_order}
    }
  end
  private :worksheet_job_hash
end
