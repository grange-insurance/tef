require 'tef/development/common_tasks'

module TEF
  def self.component_locations
    {
        'task_runner' => 'gems/task_runner',
        # todo - add this back in when we know what it is
        # 'amqlog' => 'gems/amqlog',
        'tef-core' => 'gems/tef-core',
        'tef-keeper' => 'gems/tef-keeper',
        'tef-manager' => 'gems/tef-manager',
        'tef-worker' => 'gems/tef-worker',
        'tef' => 'gems/..'
    }
  end
end
