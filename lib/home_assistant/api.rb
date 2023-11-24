module HomeAssistant
  class Error < RuntimeError
    def initialize(message)
      super("#{message[:message]} (code: #{message[:code]})")

      @message = message
    end
  end

  class API
    def initialize(connection)
      @connection = connection
      @pending = {}
      @queues = {}
      @id = 0
    end

    private def on_result(message)
      if message.success?
        Fiber.scheduler.resume(@pending.delete(message.id), message.result)
      else
        Fiber.scheduler.raise(@pending.delete(message.id), HomeAssistant::Error, message.error)
      end
    end

    private def on_event(message)
      @queues.fetch(message.id).push(message.event)
    end

    private def on_pong(message)
      Fiber.scheduler.resume(@pending.delete(message.id))
    end

    def version
      @connection.ha_version
    end

    def command(id: @id += 1, **command)
      @pending[id] = Fiber.current

      @connection.write(id: id, **command)

      Fiber.scheduler.transfer
    end

    def subscribe(id: @id += 1, **command)
      @queues[id] = Queue.new

      _ = self.command(id: id, **command)

      while event = @queues[id].pop
        yield event
      end
    end

    def ping(id: @id += 1)
      @pending[id] = Fiber.current

      @connection.write(id: id, type: "ping")

      Fiber.scheduler.transfer
    end

    def subscribe_events(event_type = nil, &block)
      message = { type: "subscribe_events" }
      message[:event_type] = event_type if event_type

      self.subscribe(**message, &block)
    end

    def subscribe_trigger(*triggers, &block)
      self.subscribe(type: "subscribe_triggers", triggers: triggers)
    end

    def fire_event(event_type, event_data = nil)
      message = { type: "fire_event", event_type: event_type }
      message[:event_data] = event_data if event_data

      self.command(**message)
    end

    def call_service(domain, service, service_data: nil, target: nil)
      message = { type: "call_service", domain: domain, service: service }
      message[:service_data] = service_data if service_data
      message[:target] = target if target

      self.command(**message)
    end

    def states
      self.command(type: "get_states")
    end

    def config
      self.command(type: "get_config")
    end

    def services
      self.command(type: "get_services")
    end

    def panels
      self.command(type: "get_panels")
    end

    def validate_config(trigger: nil, condition: nil, action: nil)
      message = { type: "validate_config" }
      message[:trigger] = trigger if trigger
      message[:condition] = condition if condition
      message[:action] = action if action

      self.command(**message)
    end
  end
end
