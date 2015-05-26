require_relative 'common_tasks'
require_relative 'bundler_tasks'


require 'cucumber/rake/task'
require 'rspec/core/rake_task'
require 'open3'


def set_cucumber_options(options)
  ENV['CUCUMBER_OPTS'] = options
end

def combine_options(set_1, set_2)
  set_2 ? "#{set_1} #{set_2}" : set_1
end


namespace 'tef' do

  task :clear_coverage do
    puts 'clearing old code coverage results...'

    # Remove previous coverage results so that they don't get merged in the new results
    code_coverage_directory = File.join(File.dirname(__FILE__), 'coverage')
    FileUtils.remove_dir(code_coverage_directory, true) if File.exists?(code_coverage_directory)
  end


  desc 'Test the entire TEF framework'
  task :test_framework, [:mode, :command_options] => [:clear_coverage, :bundle_framework] do |t, args|
    require 'simplecov'

    test_results = {}

    component_locations.each do |component, location|
      command = "bundle exec rake #{component.gsub('-', ':')}:test_everything['#{args[:command_options]}']"
      puts "Testing #{component} with: #{command}"

      test_results[component] = {}

      Dir.chdir(location) do
        stdout, stderr, status = Open3.capture3(command)

        test_results[component][:status] = status
        test_results[component][:error] = stderr
        test_results[component][:output] = stdout
      end

      if test_results[component][:status] == 0
        puts "The #{component} is working fine"
      else
        puts "There is a problem with the #{component}"
      end
    end

    bad_results = test_results.values.any? { |result| result[:status] != 0 }

    if bad_results
      puts 'There were problems with the framework!'

      test_results.each_pair do |component, results|
        if results[:status] != 0
          puts "There was a problem with the #{component}"
          puts "Exit code: #{results[:status]}"
          puts 'Std out:'
          puts results[:output]
          puts 'Std error:'
          puts results[:error]
        end
      end
    else
      puts 'Everything is shiny!'
    end
  end

  namespace 'cucumber' do
    desc 'Run all tests for the TEF'
    task :tests, [:command_options] do |t, args|
      set_cucumber_options(combine_options('-t ~@wip -t ~@off', args[:command_options]))
    end
    Cucumber::Rake::Task.new(:tests)
  end

  namespace 'rspec' do
    desc 'Run all specifications for the TEF'
    RSpec::Core::RakeTask.new(:specs, :command_options) do |t, args|
      t.rspec_opts = '--tag ~wip '
      t.rspec_opts << args[:command_options] if args[:command_options]
    end
  end

  desc 'Test everything about the TEF'
  task :test_everything, [:mode, :command_options] do |t, args|
    Rake::Task['tef:rspec:specs'].invoke(args[:command_options])
    Rake::Task['tef:cucumber:tests'].invoke(args[:command_options])
  end

end
