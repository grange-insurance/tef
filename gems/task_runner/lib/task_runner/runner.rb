module TaskRunner
  class Runner

    attr_reader :logger


    def initialize(options = {})
      configure_self(options)
    end

    def work(task)
      @logger.info "Runner: task received(id): #{task[:guid]}"
      @logger.debug "Runner: task received: #{task}"

      raise(ArgumentError, ':task must include a :task_data key') unless task.has_key? :task_data
      @logger.info "Runner: handing off to executor..."

      @executor.execute(task[:task_data])
    end


    private


    def configure_self(options)
      @logger = options.fetch(:logger, Logger.new($stdout))
      @executor = options.fetch(:executor, TaskRunner::Executor.new(logger: @logger))
    end

  end
end
