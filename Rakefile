# tests with rake's own test task
require 'rake/testtask'
Rake::TestTask.new do |t|
  t.pattern = "test/*_test.rb" # turns out, default test/*_test.rb
end

# tests with a custom task
SPECS = "./test"

desc "Run all the tests under #{SPECS}"
task :mytest do
  Dir.glob("#{SPECS}/**/*_test.rb") { |f| puts f; require f }
end

