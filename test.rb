$:.unshift("#{__dir__}/lib")

require "home_assistant"

resolvers = Resolv::DefaultResolver.instance_variable_get(:@resolvers)
resolvers << Resolv::MDNS.new

URL = "http://#{Resolv.getaddress("homeassistant.local")}:8123/api/websocket"

Async do
  endpoint = Async::HTTP::Endpoint.parse(URL)

  HomeAssistant.connect(endpoint, token: ENV.fetch("HA_TOKEN")) do |ha|
    ha.ping
    ha.subscribe_events("*") do |event|
      pp event
    end
  end
end
