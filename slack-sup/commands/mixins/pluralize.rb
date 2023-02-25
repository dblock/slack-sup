module SlackSup
  module Commands
    module Mixins
      module Pluralize
        extend ActiveSupport::Concern

        module ClassMethods
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
end
