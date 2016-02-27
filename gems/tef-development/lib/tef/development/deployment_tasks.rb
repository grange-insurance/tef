require 'tef/development/common_tasks'


namespace 'tef' do

  desc 'Spin up a manager from the current source code'
  task :create_manager => [:set_tef_environment] do
    # Assuming that the entire TEF project is present
    here = File.dirname(__FILE__)
    path_to_manager_binary = "#{here}/../../../../tef-manager/bin/start_tef_manager"

    # todo - Assuming Windows OS for the moment
    Process.spawn("start \"Manager\" cmd /c bundle exec ruby #{path_to_manager_binary}")
  end

  desc 'Spin up a worker from the current source code'
  task :create_worker => [:set_tef_environment] do
    # Assuming that the entire TEF project is present
    here = File.dirname(__FILE__)
    path_to_worker_binary = "#{here}/../../../../tef-worker/bin/start_tef_worker"

    # todo - Assuming Windows OS for the moment
    Process.spawn("start \"Worker\" cmd /c bundle exec ruby #{path_to_worker_binary}")
  end

end
