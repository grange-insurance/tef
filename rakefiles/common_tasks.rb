def component_locations
  {
      'mdf' => 'gems/mdf',
      'task_runner' => 'gems/task_runner',
      'cuke_runner' => 'gems/cuke_runner',
      'bundle_daemon' => 'gems/bundle_daemon',
      'amqlog' => 'gems/amqlog',
      'tef-core' => 'gems/tef-core',
      'tef-keeper' => 'gems/tef-keeper',
      'tef-cuke_keeper' => 'gems/tef-cuke_keeper',
      'tef-manager' => 'gems/tef-manager',
      'tef-queuebert' => 'gems/tef-queuebert',
      'tef-worker' => 'gems/tef-worker',
      'tef-worker-cuke_worker' => 'gems/tef-worker-cuke_worker',
      'tef-suite_scheduler' => 'gems/tef-suite_scheduler',
      'tef' => 'gems/..'
  }
end

namespace 'tef' do

  task :set_environment do
    ENV['TEF_ENV'] ||= 'dev'
    ENV['TEF_AMQP_URL_DEV'] ||= 'amqp://localhost:5672'
    ENV['TEF_AMQP_USER_DEV'] ||= 'guest'
    ENV['TEF_AMQP_PASSWORD_DEV'] ||= 'guest'
  end

end
