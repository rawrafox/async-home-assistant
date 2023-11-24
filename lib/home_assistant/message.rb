module HomeAssistant
  class Message
    attr_reader :message

    def self.class_for(message)
      case type = message.fetch(:type)
      when "auth_required" then HomeAssistant::Message::AuthenticationRequired
      when "auth_ok" then HomeAssistant::Message::AuthenticationOk
      when "auth_invalid" then HomeAssistant::Message::AuthenticationInvalid
      when "result" then HomeAssistant::Message::Result
      when "event" then HomeAssistant::Message::Event
      when "pong" then HomeAssistant::Message::Pong
      else
        raise ArgumentError, "Unknown message type #{type}"
      end
    end

    def initialize(message)
      @message = message
    end

    def type
      @message.fetch(:type)
    end

    class AuthenticationRequired < Message
      def ha_version
        @message.fetch(:ha_version)
      end
    end

    class AuthenticationOk < Message
    end

    class AuthenticationInvalid < Message
    end

    class Result < Message
      def id
        @message.fetch(:id)
      end
  
      def result
        @message.fetch(:result)
      end

      def error
        @message.fetch(:error)
      end

      def success?
        @message.fetch(:success)
      end
    end

    class Event < Message
      def id
        @message.fetch(:id)
      end

      def event
        @message.fetch(:event)
      end
    end

    class Pong < Message
      def id
        @message.fetch(:id)
      end
    end
  end
end