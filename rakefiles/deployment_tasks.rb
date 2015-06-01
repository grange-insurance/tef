require_relative 'common_tasks'


namespace 'tef' do

  desc 'Spin up local versions of the TEF'
  task :create_tef_farm do
    Rake::Task['tef:create_manager'].invoke
    Rake::Task['tef:create_worker'].invoke
  end

  desc 'Spin up a local version of a manager'
  task :create_manager => [:set_environment] do
    # todo - Assuming Windows OS for the moment
    Process.spawn('start "Manager" cmd /c bundle exec start_tef_manager')
  end

  desc 'Spin up a local version of a worker'
  task :create_worker => [:set_environment] do
    # todo - Assuming Windows OS for the moment
    Process.spawn('start "Worker" cmd /c bundle exec start_tef_worker')
  end

end
