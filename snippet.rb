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