class Geocoding
  require 'georuby'
  require 'geocoder'
  require 'geo_ruby/ewk'
  include GeoRuby::SimpleFeatures
  HEX_REGEX = /^[0-9A-F]+$/
  STR_REGEX = /^(-?[0-9\.]+)[\s,]+(-?[0-9\.]+)$/
  # Attempts to convert the given argument to a
  # geographic point using a number of checks
  def self.as_point(val)
    if val.nil?
      nil
    elsif Point === val
      val
    elsif Hash === val
      Point.from_x_y(val[:lng], val[:lat])
    elsif val =~ HEX_REGEX
      Point.from_hex_ewkb(val)
    elsif val =~ STR_REGEX
      coords = STR_REGEX.match(val)
      Point.from_x_y(coords[2], coords[1])
    else
      coords = Geocoder.coordinates(val)
      raise ArgumentError, %(Unable to geocode #{val.inspect}) unless coords
      Point.from_x_y(coords[1], coords[0])
    end
  end
end
