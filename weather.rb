require 'net/http'
require 'json'
require 'colorize'
require 'terminal-table'
require 'tzinfo'

# Define the API key as a constant
API_KEY_OPENWEATHERMAP = 'your-api-key'

# Base URL for the OpenWeatherMap API
BASE_URL_OPENWEATHERMAP = 'http://api.openweathermap.org/data/2.5/weather'

# Emojis for weather conditions
EMOJIS = {
  'clear' => '☀️',
  'clouds' => '☁️',
  'rain' => '🌧️',
  'snow' => '❄️',
  'thunderstorm' => '⛈️',
  'mist' => '🌫️'
}

# Cache for weather data
CACHE = {}

def get_weather_data(city_names, openweathermap_api_key)
  weather_data_collection = []

  city_names.each do |city_name|
    next if CACHE.key?(city_name)

    weather_data = fetch_data_from_openweathermap(city_name, openweathermap_api_key)

    if weather_data
      CACHE[city_name] = weather_data
      weather_data_collection << weather_data
    else
      puts "Error fetching data for #{city_name}: No data available from OpenWeatherMap."
    end
  end

  weather_data_collection
end

def fetch_data_from_openweathermap(city_name, api_key)
  uri = URI(BASE_URL_OPENWEATHERMAP)
  params = {
    'q' => city_name,
    'units' => 'metric',
    'appid' => api_key
  }
  uri.query = URI.encode_www_form(params)

  begin
    response_openweathermap = Net::HTTP.get(uri)
    weather_data_openweathermap = JSON.parse(response_openweathermap)

    temperature = weather_data_openweathermap['main']['temp']
    description = weather_data_openweathermap['weather'][0]['description']
    last_updated_utc = Time.at(weather_data_openweathermap['dt'])
    last_updated_local = TZInfo::Timezone.get('Europe/Vilnius').utc_to_local(last_updated_utc)

    emoji = ''
    EMOJIS.each do |key, value|
      if description.downcase.include?(key)
        emoji = value
        break
      end
    end

    high_temperature = weather_data_openweathermap['main']['temp_max']
    low_temperature = weather_data_openweathermap['main']['temp_min']

    return {
      'city_name' => city_name,
      'temperature' => "#{temperature.round(1)}°C #{emoji}",
      'description' => description,
      'last_updated' => last_updated_local.strftime('%Y-%m-%d %H:%M:%S %Z'),
      'high_temperature' => "#{high_temperature.round(1)}°C",
      'low_temperature' => "#{low_temperature.round(1)}°C"
    }
  rescue StandardError => e
    puts "Error fetching data from OpenWeatherMap for #{city_name}: #{e.message}"
    return nil
  end
end

def get_city_info(city_name, openweathermap_api_key)
  uri = URI('http://api.openweathermap.org/data/2.5/weather')
  params = {
    'q' => city_name,
    'units' => 'metric',
    'appid' => openweathermap_api_key
  }
  uri.query = URI.encode_www_form(params)

  begin
    response_openweathermap = Net::HTTP.get(uri)
    city_data = JSON.parse(response_openweathermap)

    population = city_data['population']
    country = city_data['sys']['country']
    coordinates = city_data['coord']

    return {
      'population' => population,
      'country' => country,
      'coordinates' => coordinates
    }
  rescue StandardError => e
    puts "Error fetching city information for #{city_name}: #{e.message}"
    return nil
  end
end

def city_specific_recommendation(description)
  case description.downcase
  when /clear/
    'Enjoy the clear sky!'
  when /clouds/
    'Cloudy skies, but no rain. You can go out.'
  when /rain/
    'It\'s raining, don\'t forget your umbrella!'
  when /snow/
    'It\'s snowing, bundle up!'
  when /thunderstorm/
    'There\'s a thunderstorm, stay indoors!'
  when /mist/
    'Be cautious while driving, visibility is low.'
  else
    'Check the weather for more details.'
  end
end

def display_menu
  puts "\nMenu Options:".colorize(:blue)
  puts "1. View Current Weather Data"
  puts "2. View Weather Forecast"
  puts "3. View City Information"
  puts "4. Exit"
  print "Enter your choice (1/2/3/4): "
end

def fetch_forecast_data(city_name, api_key)
    uri = URI('http://api.openweathermap.org/data/2.5/forecast')
    params = {
      'q' => city_name,
      'units' => 'metric',
      'appid' => api_key
    }
    uri.query = URI.encode_www_form(params)
  
    begin
      response_openweathermap = Net::HTTP.get(uri)
      forecast_data_openweathermap = JSON.parse(response_openweathermap)
  
      # Extract the relevant forecast data from the API response
      forecast_items = forecast_data_openweathermap['list'].map do |item|
        {
          'date' => Time.at(item['dt']).strftime('%Y-%m-%d %H:00 %Z'), # Hour only
          'temperature' => "#{item['main']['temp'].round(1)}°C",
          'description' => item['weather'][0]['description']
        }
      end
  
      return forecast_items
    rescue StandardError => e
      puts "Error fetching forecast data from OpenWeatherMap for #{city_name}: #{e.message}"
      return nil
    end
  end

def main
    puts 'Welcome to the Weather App!'.colorize(:blue)
  
    # Initialize user preferences
    temperature_unit = 'metric' # Default to Celsius
    date_format = '%Y-%m-%d %H:%M:%S %Z' # Default date format
  
    while true
      display_menu
      choice = gets.chomp.to_i
  
      case choice
      when 1
        print 'Enter city names separated by commas: '
        input = gets.chomp.strip
        if input.downcase != 'exit'
          city_names = input.split(',').map(&:strip)
          weather_data_collection = get_weather_data(city_names, API_KEY_OPENWEATHERMAP)
          if !weather_data_collection.empty?
            table = Terminal::Table.new do |t|
              t.title = 'Current Weather Data'
              t.headings = ['City', 'Temperature', 'High', 'Low', 'Weather Condition', 'Last Updated', 'Recommendation']
              weather_data_collection.each do |weather_data|
                recommendation = city_specific_recommendation(weather_data['description'])
                city_info = get_city_info(weather_data['city_name'], API_KEY_OPENWEATHERMAP)
                t.add_row [
                  weather_data['city_name'].capitalize,
                  weather_data['temperature'],
                  weather_data['high_temperature'],
                  weather_data['low_temperature'],
                  weather_data['description'],
                  weather_data['last_updated'],
                  recommendation
                ]
                if city_info['population']
                  t.add_row ['Population:', city_info['population']]
                end
              end
            end
            puts table
          end
        end
      when 2
        print 'Enter city names separated by commas: '
        input = gets.chomp.strip
        if input.downcase != 'exit'
          city_names = input.split(',').map(&:strip)
          forecast_data_collection = {}
          city_names.each do |city_name|
            forecast = fetch_forecast_data(city_name, API_KEY_OPENWEATHERMAP)
            forecast_data_collection[city_name] = forecast if forecast
          end
          forecast_data_collection.each do |city, forecast|
            puts "\n#{city.capitalize} Forecast:"
            grouped_forecast = forecast.group_by { |item| Date.parse(item['date']).strftime('%A, %b %d') } # Include day of the week
            grouped_forecast.each do |date, hourly_forecast|
              puts "\n#{date}"
              forecast_table = Terminal::Table.new do |t|
                t.headings = ['Time', 'Temperature', 'Weather Condition']
                hourly_forecast.each do |forecast_item|
                  t.add_row [
                    forecast_item['date'].split[1], # Display time
                    forecast_item['temperature'],
                    forecast_item['description']
                  ]
                end
              end
              puts forecast_table
            end
          end
        end
      when 3
        print 'Enter city names separated by commas: '
        input = gets.chomp.strip
        if input.downcase != 'exit'
          city_names = input.split(',').map(&:strip)
          city_info_collection = {}
          city_names.each do |city_name|
            city_info = get_city_info(city_name, API_KEY_OPENWEATHERMAP)
            city_info_collection[city_name] = city_info if city_info
          end
          city_info_collection.each do |city, info|
            puts "\n#{city.capitalize} Information:"
            if info['population']
              puts "Population: #{info['population']}"
            else
              puts "Population information not available."
            end
            puts "Country: #{info['country']}"
            puts "Coordinates: Latitude #{info['coordinates']['lat']}, Longitude #{info['coordinates']['lon']}"
          end
        end
      when 4
        puts 'Goodbye!'.colorize(:blue)
        break
      else
        puts 'Invalid choice. Please select a valid option (1/2/3/4).'.colorize(:red)
      end
    end
  end
  
main if __FILE__ == $PROGRAM_NAME
