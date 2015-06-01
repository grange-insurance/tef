require 'open3'
require 'logger'

module TaskRunner
  class Executor

    attr_reader :logger

    def initialize(options = {})
      @logger = options.fetch(:logger, Logger.new($stdout))
    end

    def execute(task_data)
      @logger.debug("Executor: executing task: #{task_data}")
      raise(ArgumentError, ':task_data must include a :command key') unless task_data.has_key? :command
      raise(ArgumentError, ':task_data must include a :working_directory key') unless task_data.has_key? :working_directory
      raise(ArgumentError, ':working_directory must exist and be a directory') unless File.directory?(task_data[:working_directory])

      old_wd = Dir.pwd
      Dir.chdir task_data[:working_directory]


      execution_data = []

      if task_data[:env_vars]
        raise(ArgumentError, ":env_vars must be a Hash, got: #{task_data[:env_vars].class}") unless task_data[:env_vars].is_a?(Hash)
        execution_data << task_data[:env_vars]
      end

      @logger.debug("command is: #{task_data[:command]}")
      execution_data << task_data[:command]

      stdout, stderr, status = Open3.capture3(*execution_data)
      #stdout, stderr, status = open3_with_timeout(*execution_data)
      Dir.chdir old_wd

      {stdout: stdout, stderr: stderr, status: status}
    end

    private
    def open3_with_timeout(cmd)
      inp, out, err, wait_thr = Open3.popen3(cmd)
      inp.close

      did_timeout = false

      still_open = [out, err]  # Array that only contains the opened streams
      output_buffer = ''
      stderr_buffer = ''
      output_lines = []
      stderr_lines = []

      while !still_open.empty?
        fhs = select(still_open, nil, nil, 300)
        output_lines.concat handle_io(still_open, fhs[0], out, output_buffer) unless fhs.nil?
        stderr_lines.concat handle_io(still_open, fhs[0], err, stderr_buffer) unless fhs.nil?
        if fhs.nil?
          did_timeout = true
          still_open.clear
        end
      end

      out.close
      err.close
      @logger.error 'Timeout waiting for output from cucumber' if did_timeout
      result = did_timeout ? nil : wait_thr.value
      return output_lines, stderr_lines, result
    end

    def handle_io(still_open, io_array, io, buffer)

      lines = []
      if io_array.include?(io)
        begin
          buffer << io.readpartial(4096)
          have_newline = buffer =~ /([^\n]+)\z/ ? $1 : nil

          buffer.scan(/.*\n/) do |line|
            lines << line.chomp
          end

          if have_newline
            buffer.replace(have_newline)
          else
            buffer.clear
          end
        rescue EOFError
          still_open.delete_if{|s| s == io}
        end
      end
      @logger.debug lines
      lines
    end

  end
end
