# frozen_string_literal: true

require_relative 'helpers/message_handler'
require_relative 'current_event'

module Sequent
  module Core
    class Workflow
      include Helpers::MessageHandler

      def self.on(*message_classes, &block)
        decorated_block = ->(event) do
          begin
            old_event = CurrentEvent.current
            CurrentEvent.current = event
            instance_exec(event, &block)
          ensure
            CurrentEvent.current = old_event
          end
        end
        super(*message_classes, &decorated_block)
      end

      def execute_commands(*commands)
        Sequent.configuration.command_service.execute_commands(*commands)
      end

      # Workflow#after_commit will accept a block to execute
      # after the transaction commits. This is very useful to
      # isolate side-effects. They will run only on the
      # transaction's success and will not be able to roll it
      # back when there is an exception. Useful if your background
      # jobs processor is not using the same database connection
      # to enqueue jobs.
      def after_commit(ignore_errors: false, &block)
        Sequent.configuration.transaction_provider.after_commit(&block)
      rescue StandardError => e
        if ignore_errors
          Sequent.logger.warn("An exception was raised in an after_commit hook: #{e}, #{e.inspect}")
        else
          raise e
        end
      end
    end
  end
end
