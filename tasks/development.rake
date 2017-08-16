import 'tasks/rubocop.rake'
import 'tasks/rspec.rake'

task default: %i[rubocop spec]
