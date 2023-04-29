# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Names
        module_function

        # migration_action values indicating row should be kept as a name authority
        def keep_actions
          ["", nil, "main", "ok"]
        end

        # migration_action values indicating row needs to be handled not as a name authority
        def to_merge
          ["add_contact", "merge_variant", "use_name"]
        end
      end
    end
  end
end
