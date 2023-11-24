module HomeAssistant
  class Connection
    attr_accessor :state
    attr_accessor :ha_version

    def initialize(ws, token:)
      @ws = ws
      @state = HomeAssistant::State::InitialState.new(self, token: token)
      @ha_version = nil
      @api = Async::Variable.new
    end

    def on_message(message)
      @state.on_message(Message.class_for(message).new(message))
    end

    def api
      @api.value
    end

    def api=(api)
      @api.resolve(api)
    end

    def write(**message)
      @ws.write(message.to_json)
      @ws.flush
    end
  end
end
