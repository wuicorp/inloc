class FlagsMap
  include Mongoid::Document

  field :app_key, type: String
  field :cells, type: Hash, default: {}
  field :flags, type: Hash, default: {}

  # Adds a flag to the map:
  #   1. Add the flag in any localization cell into the area
  #      inside (longitude, latitude, radius).
  #
  #   2. Add in flags[:id] the cells ("longitude:latitude") where
  #      the flag is added.
  #
  #   We maintain 2 hashes due to performance reasons:
  #     a. The "cells" hash alows us to know instantly what flags are covering
  #        some specific point in the map.
  #
  #     b. The "flags" hash alows us to know instantly what cells are covered
  #        by some specific flag.
  #
  #   ADVISE:
  #     The area to cover is rectangular shape to make it simpler.
  #
  # @param [Hash] params flag attributes
  # @option params [String] :id flag id
  # @option params [String] :longitude longitude coordinate in degrees
  # @option params [String] :latitude latitude coordinate in degrees
  # @option params [String] :radius radius area to cover en meters.
  def add_flag(params)
    lon = params[:longitude].to_f
    lat = params[:latitude].to_f
    radius = params[:radius].to_i

    cells_for(lon, lat, radius) do |cell_id|
      add_flag_to_cell(params[:id].to_s, cell_id)
    end
  end

  # Removes a flag from the map:
  #   1. Remove the flag from the flags hash.
  #   2. Remove the flag from all related cells.
  #
  # @param [String] flag_id flag to remove
  def remove_flag(flag_id)
    flag_cells = flags.delete(flag_id.to_s)
    return unless flag_cells

    flag_cells.each do |cell_id|
      cells[cell_id].delete(flag_id.to_s)
      cells.delete(cell_id) if cells[cell_id].empty?
    end
  end

  def find_flags_by_position(longitude, latitude)
    lon, lat = cell(longitude.to_f, latitude.to_f)
    cells[build_cell_id(lon, lat)] || []
  end

  # Adds a flag id to the specified cell, but also adds the cell_id
  #   in the corresponding flag.
  #
  # @param [String] flag_id flag to localize
  # @param [String] cell_id localization cell ("longitude:latitude")
  def add_flag_to_cell(flag_id, cell_id)
    cell_flags = ((cells[cell_id] || []) << flag_id).uniq
    cells[cell_id] = cell_flags

    flag_cells = ((flags[flag_id] || []) << cell_id).uniq
    flags[flag_id] = flag_cells
  end

  def cells_for(longitude, latitude, radius)
    start_lon, start_lat, end_lon, end_lat = rect(longitude, latitude, radius)

    (start_lon..end_lon).step(bitx).each do |lon_cell|
      (start_lat..end_lat).step(bity).each do |lat_cell|
        next if lat_cell > max_latitude
        next if lat_cell < -max_latitude
        lon_cell -= 2 * max_longitude if lon_cell > max_longitude
        lon_cell += 2 * max_longitude if lon_cell < -max_longitude

        yield build_cell_id(lon_cell, lat_cell)
      end
    end
  end

  def rect(longitude, latitude, radius)
    center_lon, center_lat = cell(longitude, latitude)

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

  def build_cell_id(longitude, latitude)
    lon_index = longitude.to_s.sub('.', ',')
    lat_index = latitude.to_s.sub('.', ',')
    "#{lon_index}:#{lat_index}"
  end

  def cell(longitude, latitude)
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
