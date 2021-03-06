require "bundler/setup"
require "datacaster"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  if ENV['LINE_NUMBERS']
    range_start, range_stop = ENV['LINE_NUMBERS'].split(/[-,]/)
    range = Integer(range_start)..Integer(range_stop)
    config.filter_run_including(line_number: ->(line_number) { range.include?(line_number) })
  end
end
