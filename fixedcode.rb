require 'net/http'
require 'json'
require 'tzinfo'

class OpenWeatherMapApiClient
  BASE_URL_OPENWEATHERMAP = 'http://api.openweathermap.org/data/2.5/weather'.freeze
  EMOJIS = {
    'clear' => '☀️',
    'clouds' => '☁️',
    'rain' => '🌧️',
    # Add more emoji mappings as needed
  }.freeze
  TIMEZONE = TZInfo::Timezone.get('Europe/Vilnius')

  def self.fetch_data(city_name, api_key)
    uri = URI(BASE_URL_OPENWEATHERMAP)
    params = {
      'q' => city_name,
      'units' => 'metric',
      'appid' => api_key
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get(uri)
    weather_data = JSON.parse(response)

    decorate_data(city_name, weather_data)
  rescue StandardError => e
    puts "Error fetching data from OpenWeatherMap for #{city_name}: #{e.message}"
    nil
  end

  def self.decorate_data(city_name, weather_data)
    temperature = weather_data['main']['temp']
    description = weather_data['weather'][0]['description']
    last_updated_utc = Time.at(weather_data['dt'])
    last_updated_local = TIMEZONE.utc_to_local(last_updated_utc)

    emoji = find_emoji(description)

    high_temperature = weather_data['main']['temp_max']
    low_temperature = weather_data['main']['temp_min']

    build_dto(city_name, temperature, description, last_updated_local, emoji, high_temperature, low_temperature)
  end

  def self.find_emoji(description)
    emoji = ''
    EMOJIS.each do |key, value|
      if description.downcase.include?(key)
        emoji = value
        break
      end
    end
    emoji
  end

  def self.build_dto(city_name, temperature, description, last_updated_local, emoji, high_temperature, low_temperature)
    {
      'city_name' => city_name,
      'temperature' => "#{temperature.round(1)}°C #{emoji}",
      'description' => description,
      'last_updated' => last_updated_local.strftime('%Y-%m-%d %H:%M:%S %Z'),
      'high_temperature' => "#{high_temperature.round(1)}°C",
      'low_temperature' => "#{low_temperature.round(1)}°C"
    }
  end
end