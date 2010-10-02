
module RPMContrib
  module Instrumentation
    # == Backgrounded Resque Instrumentation
    #
    # Installs a hook to ensure the agent starts manually when the worker
    # starts and also adds the tracer to the process method which executes
    # in the forked task.
    module BackgroundedResqueInstrumentation
      ::Resque::Job.class_eval do
        include NewRelic::Agent::Instrumentation::ControllerInstrumentation
        
        old_perform_method = instance_method(:perform)

        define_method(:perform) do
          class_name = args.first
          method = args[1]
          NewRelic::Agent.reset_stats if NewRelic::Agent.respond_to? :reset_stats
          perform_action_with_newrelic_trace(:name => method, :class_name => class_name, :params => @payload
                                             :category => 'OtherTransaction/BackgroundedResqueJob') do
            old_perform_method.bind(self).call
          end

          NewRelic::Agent.shutdown unless defined?(::Resque.before_child_exit)
        end
      end

      if defined?(::Resque.before_child_exit)
        ::Resque.before_child_exit do |worker|
          NewRelic::Agent.shutdown
        end
      end
    end
  end
end if defined?(::Backgrounded::Handler::ResqueHandler) and not NewRelic::Control.instance['disable_backgrounded_resque']
