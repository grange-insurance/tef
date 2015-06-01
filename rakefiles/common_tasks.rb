module TEF
  def self.component_locations
    {
        'task_runner' => 'gems/task_runner',
        'amqlog' => 'gems/amqlog',
        'tef-core' => 'gems/tef-core',
        'tef-keeper' => 'gems/tef-keeper',
        'tef-manager' => 'gems/tef-manager',
        'tef-worker' => 'gems/tef-worker',
        'tef' => 'gems/..'
    }
  end
end

namespace 'tef' do

  task :set_environment do
    ENV['TEF_ENV'] ||= 'dev'
    ENV['TEF_AMQP_URL_DEV'] ||= 'amqp://localhost:5672'
    ENV['TEF_AMQP_USER_DEV'] ||= 'guest'
    ENV['TEF_AMQP_PASSWORD_DEV'] ||= 'guest'
  end

end
