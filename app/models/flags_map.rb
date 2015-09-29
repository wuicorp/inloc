class FlagsMap
  include Mongoid::Document

  attr_accessor :longitude, :latitude, :radius

  field :application_id, type: String
  has_many :flags

  validates_numericality_of :longitude
  validates_numericality_of :latitude
  validates_numericality_of :radius

  # Adds a flag to the map:
  #
  #   NOTE:
  #     1. The area to cover is rectangular shape to make it simpler.
  #     2. If the flag exists it updates the corresponding area.
  #
  # @param [Hash] params flag attributes
  # @option params [String] :id flag id
  # @option params [String] :longitude longitude coordinate in degrees
  # @option params [String] :latitude latitude coordinate in degrees
  # @option params [String] :radius radius area to cover en meters.
  def add_flag(params)
    self.attributes = params.slice(:longitude, :latitude, :radius)
    return false unless valid?

    flag_id = params[:id]
    remove_flag(flag_id) if flag_exist?(flag_id)

    lon = params[:longitude].to_f
    lat = params[:latitude].to_f
    radius = params[:radius].to_i

    cells_for(lon, lat, radius) do |cell|
      add_flag_to_cell(flag_id.to_s, cell)
    end
    true
  end

  def flag_exist?(id)
    flags.where(id: id).exists? ? true : false
  end

  def remove_flag(flag_id)
    flag = flags.find_by(id: flag_id)
    return unless flag
    flag.destroy
  end

  def find_flags_by_position(longitude, latitude)
    lon, lat = cell_point(longitude.to_f, latitude.to_f)

    cell = Cell.find_by(longitude: lon, latitude: lat)
    cell.flags if cell
  end

  def add_flag_to_cell(flag_id, cell)
    cell.find_or_create_flag_by(id: flag_id, flags_map: self)
  end

  def cells_for(longitude, latitude, radius)
    start_lon, start_lat, end_lon, end_lat = rect(longitude, latitude, radius)

    (start_lon..end_lon).step(bitx).each do |lon_cell|
      (start_lat..end_lat).step(bity).each do |lat_cell|
        next if lat_cell > max_latitude
        next if lat_cell < -max_latitude
        lon_cell -= 2 * max_longitude if lon_cell > max_longitude
        lon_cell += 2 * max_longitude if lon_cell < -max_longitude

        yield Cell.find_or_create_by(longitude: lon_cell, latitude: lat_cell)
      end
    end
  end

  def rect(longitude, latitude, radius)
    center_lon, center_lat = cell_point(longitude, latitude)

    steps_x, steps_y = steps_from_radius(radius)

    start_lon = center_lon - (bitx * steps_x)
    start_lat = center_lat - (bity * steps_y)

    ending_lon = start_lon + (bitx * steps_x * 2)
    ending_lat = start_lat + (bity * steps_y * 2)

    [start_lon, start_lat, ending_lon, ending_lat]
  end

  # Calculate number of coordinate steps for a specified radius.
  #   Steps are cells in the matrix which defines the flags map.
  #
  # @param [Integer] radius in meters
  # @return [Integer] steps required to accomplish the radius
  def steps_from_radius(radius)
    deg_radius = meters_to_degrees(radius)
    steps_x = (deg_radius / bitx).to_i
    steps_y = (deg_radius / bity).to_i
    [steps_x, steps_y]
  end

  def cell_point(longitude, latitude)
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
