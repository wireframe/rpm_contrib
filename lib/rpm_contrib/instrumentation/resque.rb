
module RPMContrib
  module Instrumentation
    # == Resque Instrumentation
    #
    # Installs a hook to ensure the agent starts manually when the worker
    # starts and also adds the tracer to the process method which executes
    # in the forked task.
    module ResqueInstrumentation
      ::Resque::Job.class_eval do
        include NewRelic::Agent::Instrumentation::ControllerInstrumentation
        
        old_perform_method = instance_method(:perform)

        define_method(:perform) do
          NewRelic::Agent.reset_stats if NewRelic::Agent.respond_to? :reset_stats
          perform_action_with_newrelic_trace(trace_options) do
            old_perform_method.bind(self).call
          end

          NewRelic::Agent.shutdown unless defined?(::Resque.before_child_exit)
        end

        private
        def backgrounded_job?
          if defined?(::Backgrounded::Handler::ResqueHandler) && self.is_a?(::Backgrounded::Handler::ResqueHandler)
        end
        def trace_options
          if backgrounded_job?
            {
              :class_name => args[0],
              :name => args[2].to_s,
              :params => @payload,
              :category => 'OtherTransaction/BackgroundedResqueJob'
            }
          else
            class_name = (payload_class ||self.class).name
            {
              :class_name => class_name,
              :name => 'perform',
              :category => 'OtherTransaction/ResqueJob'
            }
          end
        end
      end

      if defined?(::Resque.before_child_exit)
        ::Resque.before_child_exit do |worker|
          NewRelic::Agent.shutdown
        end
      end
    end
  end
end if defined?(::Resque::Job) and not NewRelic::Control.instance['disable_resque']
