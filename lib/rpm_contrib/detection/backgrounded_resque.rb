# Detect when running backgrounded with resque and set the framework and dispatcher.

module NewRelic
  class LocalEnvironment
    module BackgroundedResque
      def discover_dispatcher
        super
        if defined?(::Backgrounded::Handler::ResqueHandler) && @dispatcher.nil?
          @dispatcher = 'backgrounded_resque'
        end
      end
    end
  end
end

