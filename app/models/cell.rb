class Cell
  include Mongoid::Document

  field :longitude, type: BigDecimal
  field :latitude, type: BigDecimal

  has_and_belongs_to_many :flags

  class << self
    def at(longitude, latitude)
      lon, lat = point(longitude.to_f, latitude.to_f)
      find_by(longitude: lon, latitude: lat)
    end

    def cells_for(longitude, latitude, radius)
      start_lon, start_lat, end_lon, end_lat = rect(longitude, latitude, radius)

      (start_lon..end_lon).step(bitx).each do |lon_cell|
        (start_lat..end_lat).step(bity).each do |lat_cell|
          next if lat_cell > max_latitude
          next if lat_cell < -max_latitude
          lon_cell -= 2 * max_longitude if lon_cell > max_longitude
          lon_cell += 2 * max_longitude if lon_cell < -max_longitude

          yield find_or_create_by(longitude: lon_cell, latitude: lat_cell)
        end
      end
    end

    def rect(longitude, latitude, radius)
      center_lon, center_lat = point(longitude, latitude)

      steps_x, steps_y = steps_from_radius(radius)

      start_lon = center_lon - (bitx * steps_x)
      start_lat = center_lat - (bity * steps_y)

      ending_lon = start_lon + (bitx * steps_x * 2)
      ending_lat = start_lat + (bity * steps_y * 2)

      [start_lon, start_lat, ending_lon, ending_lat]
    end

    def steps_from_radius(radius)
      deg_radius = meters_to_degrees(radius)
      steps_x = (deg_radius / Cell.bitx).to_i
      steps_y = (deg_radius / Cell.bity).to_i
      [steps_x, steps_y]
    end

    def point(longitude, latitude)
      lon = (longitude / bitx).to_i * bitx
      lat = (latitude / bity).to_i * bity
      [lon, lat]
    end

    def bitx
      @bitx ||= max_longitude / 4_000_000
    end

    def bity
      @bity ||= max_latitude / 2_000_000
    end

    def max_longitude
      @max_longitude ||= BigDecimal.new(180.0.to_s)
    end

    def max_latitude
      @max_latitude ||= BigDecimal.new(85.0.to_s)
    end

    def meters_to_degrees(value)
      BigDecimal.new((value / 111_000.0).to_s)
    end
  end
end
