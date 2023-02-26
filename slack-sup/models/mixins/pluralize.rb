module SlackSup
  module Models
    module Mixins
      module Pluralize
        extend ActiveSupport::Concern

        def pluralize(count, text)
          case count
          when 1
            "#{count} #{text}"
          else
            "#{count} #{text.pluralize}"
          end
        end
      end
    end
  end
end
