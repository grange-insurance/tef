require "tef/development/version"
require 'sys/proctable'


module TEF
  module Development

    include Sys


    def kill_existing_tef_processes
      puts "Checking for old TEF processes to kill..."

      tef_pids = []
      tef_pattern = /start_tef_/

      ProcTable.ps do |process|
        if process.cmdline =~ tef_pattern
          puts "Marking process #{process.pid} (#{process.cmdline}) for killing"
          tef_pids << process.pid
        end
      end

      tef_pids.each do |tef_pid|
        puts "Killing process #{tef_pid}"
        Process.kill('KILL', tef_pid)
      end
    end

    def get_queue(queue_name)
      @bunny_channel.queue(queue_name, passive: true)
    end

    def delete_queue(queue_name)
      @bunny_channel.queue_delete(queue_name)
    end

  end
end
