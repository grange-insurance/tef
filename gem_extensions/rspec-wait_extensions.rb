# Patched to allow the timeout to be changed instead of always using the hardcoded timeout

module RSpec
  module Wait
    module Handler
      @wait_timeout = TIMEOUT

      def self.set_wait_timeout(seconds)
        @wait_timeout = seconds
      end

      def self.current_wait_timeout
        @wait_timeout
      end


      # Just had to change the timeout from a constant to a variable
      def handle_matcher(target, *args, &block)
        failure = nil

        Timeout.timeout(RSpec::Wait::Handler.current_wait_timeout) do
          loop do
            begin
              actual = target.respond_to?(:call) ? target.call : target
              super(actual, *args, &block)
              break
            rescue RSpec::Expectations::ExpectationNotMetError => failure
              sleep DELAY
              retry
            end
          end
        end
      rescue Timeout::Error
        raise failure || TimeoutError
      end

      # From: https://github.com/rspec/rspec-expectations/blob/v3.0.0/lib/rspec/expectations/handler.rb#L44-L63
      class PositiveHandler < RSpec::Expectations::PositiveExpectationHandler
        extend Handler
      end

      # From: https://github.com/rspec/rspec-expectations/blob/v3.0.0/lib/rspec/expectations/handler.rb#L66-L93
      class NegativeHandler < RSpec::Expectations::NegativeExpectationHandler
        extend Handler
      end

    end
  end
end
