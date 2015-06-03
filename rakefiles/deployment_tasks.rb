require_relative 'common_tasks'
require 'tef/development/deployment_tasks'


namespace 'tef' do

  desc 'Spin up local versions of the TEF'
  task :create_tef_farm do
    Rake::Task['tef:create_manager'].invoke
    Rake::Task['tef:create_queuebert'].invoke
    Rake::Task['tef:create_worker'].invoke
  end

end
