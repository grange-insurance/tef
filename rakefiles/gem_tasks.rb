require_relative 'common_tasks'


namespace 'tef' do

  desc 'Build all gems'
  task :build_gems do
    @built_gems = []

    TEF.component_locations.each do |component, location|
      next unless location =~ /^gems/

      puts "Building gem #{component} from #{location}"
      Dir.chdir(location) do
        output = IO.popen("gem build #{component}.gemspec").read
        gem_file = output[/#{component}.*\.gem/]

        @built_gems << "#{location}/#{gem_file}"
      end
    end
  end

  desc 'Install all gems'
  task :install_gems, [:install_options] => [:build_gems] do |t, args|
    @built_gems.each do |gem_file|
      command = "gem install #{gem_file}"
      command += " #{args[:install_options]}" if args[:install_options]

      puts "Installing gem at #{gem_file}"
      puts "with command: #{command}"

      system(command)
    end
  end

  desc 'Push gems to Geminabox'
  task :box_gems, [:gem_host] => [:build_gems] do |t, args|
    host_location = args[:gem_host]

    @built_gems.each do |gem_file|
      puts "Pushing gem #{gem_file} to Geminabox at #{host_location}"
      command = "gem inabox #{gem_file} -g #{host_location} -o"
      puts "command: #{command}"

      system(command)
    end
  end
  desc 'builds and copies the gems for docker'
  task :docker_gems => [:build_gems] do
    @built_gems.each do |gem_file|
      puts "#{gem_file}"
      system("cp #{gem_file} docker/gems/")
    end
  end

end
