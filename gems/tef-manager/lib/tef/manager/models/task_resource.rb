require 'active_record'

# todo - test this class more
module TEF
  module Manager
    # Database object for resources used by tasks
    class TaskResource < ActiveRecord::Base
      belongs_to :task, autosave: true
    end
  end
end
