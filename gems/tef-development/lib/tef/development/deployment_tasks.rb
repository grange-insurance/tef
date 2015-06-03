require 'tef/development/common_tasks'


namespace 'tef' do

  desc 'Spin up a local version of a manager'
  task :create_manager => [:set_tef_environment] do
    # todo - Assuming Windows OS for the moment
    Process.spawn('start "Manager" cmd /c bundle exec start_tef_manager')
  end

  desc 'Spin up a local version of a worker'
  task :create_worker => [:set_tef_environment] do
    # todo - Assuming Windows OS for the moment
    Process.spawn('start "Worker" cmd /c bundle exec start_tef_worker')
  end

end
