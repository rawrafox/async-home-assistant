#!/usr/bin/env ruby

require "async"
require "async/io/stream"
require "async/http/endpoint"
require "async/websocket/client"

require "home_assistant/api"
require "home_assistant/connection"
require "home_assistant/state"
require "home_assistant/message"

module HomeAssistant
  def self.connect(endpoint, token:)
    Async::WebSocket::Client.connect(endpoint) do |ws|
      connection = HomeAssistant::Connection.new(ws, token: token)

      Async(transient: true) do
        while message = ws.read
          case message
          when Protocol::WebSocket::TextMessage
            message = JSON.parse(message, symbolize_names: true)
            connection.on_message(message)
          else
            raise ArgumentError, "Unsupported WebSocket message #{message.inspect} from HA"
          end
        end
      end

      yield connection.api
    end
  end
end
