require 'httparty'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class Centralize

  def initialize(location, entity, center_slice=1, precision=0.001)
    @apikey          = 'AIzaSyAQALvEod8LCxEbScaeOvx2cdJLWoQpHwE'
    @search_location = location
    @search_entity   = entity
    @center_slice    = center_slice
    @precision       = precision
  end

  def run
    puts "SEARCHING FOR: #{@search_entity} in #{@search_location} (city radius: 1:#{@center_slice} of total)"

    results = geocode(@search_location)

    if !results.empty?
      @location = results["results"][0]["geometry"]["location"]
      @radius   = get_radius(@location) / @center_slice

      # Don't even really seem to need this, maps API takes a radius and
      # works the rest out by itself.
      # @circumference = 2 * Math::PI * (@radius / @center_slice)

      print_entities(@location, @radius, @search_entity)
    else
      puts "Could not find location: #{@search_location}"
    end
  end

  private

  def print_entities(location, radius, search_entity, keyword=nil)
    radius = radius

    puts "CENTER RADIUS: #{radius}"
    puts
    puts "---RESULTS---"

    results = HTTParty.get(
      "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=#{location["lat"]},#{location["lng"]}&radius=#{radius}&type=#{search_entity}&key=#{@apikey}"
    )

    puts results["results"].map{|r| "#{r["name"]} - #{r["vicinity"]}\n"}
  end

  def convert_to_meters(o_lat, o_lng, d_lat, d_lng)
    r     = 6378.137
    n_lat = d_lat * Math::PI / 180 - o_lat * Math::PI / 180
    n_lng = d_lng * Math::PI / 180 - o_lng * Math::PI / 180

    a = Math.sin(n_lat / 2) * Math.sin(n_lat / 2) +
        Math::cos(o_lat * Math::PI / 180) * Math.cos(d_lat * Math::PI / 180) *
        Math.sin(n_lng / 2) * Math.sin(n_lng / 2)

    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    d = r * c

    return d * 1000
  end

  def get_radius(origin)
    start     = origin["lat"].to_f
    direction = start
    searching = true

    puts 'DRAWING POINTS FROM CENTER TO EDGE'

    while(searching == true) do
      found = false
      printf "."

      direction = direction.to_f + @precision
      result = reverse_geocode(direction, origin["lng"])

      result["results"][0]["address_components"].each do |result|
        result.each do |key, value|
          begin
            if value.upcase == @search_location.upcase
              found = true
            end
          rescue
          end
        end
      end

      if !found
        searching = false
        puts "REACHED EDGE OF THE CITY"
      end
    end
    puts

    finish = direction.to_f
    meters = convert_to_meters(start, origin["lng"].to_f, finish, origin["lng"].to_f)

    puts "TOTAL CITY RADIUS: #{meters}"

    return meters
  end

  def geocode(address)
    HTTParty.get("https://maps.googleapis.com/maps/api/geocode/json?address=#{address}&key=#{@apikey}")
  end

  def reverse_geocode(lat, lng)
    HTTParty.get("https://maps.googleapis.com/maps/api/geocode/json?latlng=#{lat},#{lng}&key=#{@apikey}")
  end

end

#EXAMPLE: ruby centralize.rb paris hospital

centralize = Centralize.new(ARGV[0], ARGV[1], 3, 0.001)
centralize.run
