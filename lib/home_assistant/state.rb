module HomeAssistant
  class State
    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def on_message(message)
      raise ArgumentError, "Current Home Assistant connection state (#{self.class.name}) does not support the message #{message.inspect}"
    end

    class InitialState < State
      def initialize(connection, token:)
        super(connection)

        @token = token
      end

      def on_message(message)
        if message.is_a? HomeAssistant::Message::AuthenticationRequired
          @connection.state = AuthenticatingState.new(self.connection)
          @connection.ha_version = message.ha_version
          @connection.write(type: "auth", access_token: @token)
        else
          super(message)
        end
      end
    end

    class AuthenticatingState < State
      def on_message(message)
        case message
        when HomeAssistant::Message::AuthenticationOk
          @connection.state = ConnectedState.new(self.connection)
        when HomeAssistant::Message::AuthenticationInvalid
          raise ArgumentError, "Invalid Home Assistant API token"
        else
          super(message)
        end
      end
    end

    class ConnectedState < HomeAssistant::State
      attr_reader :api

      def initialize(connection)
        super(connection)

        @api = API.new(connection)

        connection.api = @api
      end

      def on_message(message)
        case message
        when HomeAssistant::Message::Result
          @api.send(:on_result, message)
        when HomeAssistant::Message::Event
          @api.send(:on_event, message)
        when HomeAssistant::Message::Pong
          @api.send(:on_pong, message)
        else
          super(message)
        end
      end
    end
  end
end
