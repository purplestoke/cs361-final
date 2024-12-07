#!/usr/bin/env ruby
require 'json'

# A COLLECTION OF TRACK SEGMENTS WITH AN OPTIONAL NAME
class Track
  def initialize(segments, name=nil)
    @name = name

    # USE map TO CREATE TrackSegment OBJECTS DIRECTLY
    @segments = segments.map {|s| TrackSegment.new(s) }
  end

  # GENERATES GeoJSON REPRESENTATION OF THE Track
  def get_track_json
    {
      type: "Feature",
      properties: @name ? {title: @name} : {},
      geometry: {
        type: "MultiLineString",
        coordinates: @segments.map(&:to_coordinates)
      }
    }.to_json
  end

  def to_geojson
    JSON.parse(get_track_json)
  end
end

# REPRESENTS THE segment OF A Track CONSISTING OF MULTIPLE POINTS
class TrackSegment
  attr_reader :coordinates

  def initialize(coordinates)
    @coordinates = coordinates
  end

  # CONVERT segment points INTO AN ARRAY OF COORDINATES
  def to_coordinates
    @coordinates.map(&:to_array)
  end
end

# REPRESENTS A GEOGRAPHIC POINT
class Point
  attr_reader :lat, :lon, :ele

  def initialize(lon, lat, ele=nil)
    @lon = lon
    @lat = lat
    @ele = ele
  end
  # CONVERTS THE POINT TO AN ARRAY FORMAT
  # ARRAY FORMAT WORKS WITH geojson
  def to_array
    ele ? [lon, lat, ele] : [lon, lat]
  end
end

# REPRESENTS A SINGLE POINT OF INTEREST
# OPTIONAL name AND type
class Waypoint
  attr_reader :lat, :lon, :ele, :name, :type

  def initialize(lon, lat, ele=nil, name=nil, type=nil)
    @lon = lon
    @lat = lat
    @ele = ele
    @name = name
    @type = type
  end

  # CREATES THE geojson REPRESENTATION OF THE Waypoint
  def get_waypoint_json
    feature = {
      type: "Feature",
      geometry: {
        type: "Point",
        coordinates: ele ? [lon, lat, ele] : [lon, lat]
      }
    }

    # ADDS name AND type IF PROVIDED
    if name || type
      feature[:properties] = {}
      feature[:properties][:title] = name if name
      feature[:properties][:icon] = type if type
    end
    feature.to_json
  end

  def to_geojson
    JSON.parse(get_waypoint_json)
  end

end

# A COLLECTION OF GEOGRAPHIC FEATURES (Tracks AND Waypoints)
class World
  def initialize(name, features)
    @name = name
    @features = features
  end

  def add_feature(feature)
    @features.append(feature)
  end

  # CONVERTS THE World AND ITS features TO geojson FORMAT
  def to_geojson
    {
      type: "FeatureCollection",
      features: @features.map do |feature|
        # EACH feature HANDLES ITS OWN geojson GENERATION
        case feature
        when Track then feature.to_geojson
        when Waypoint then feature.to_geojson
        end
      end
      # CLEAN JSON OUTPUT
    }.to_json
  end
end

# CREATE AND OUTPUT DATA IN geojson FORMAT
def main

  # CREATE NEW SAMPLE Waypoints
  w = Waypoint.new(-121.5, 45.5, 30, "home", "flag")
  w2 = Waypoint.new(-121.5, 45.6, nil, "store", "dot")

  # CREATE SAMPLE TRACK Segments
  ts1 = [Point.new(-122, 45), Point.new(-122, 46), Point.new(-121, 46)]
  ts2 = [Point.new(-121, 45), Point.new(-121, 46)]
  ts3 = [Point.new(-121, 45.5), Point.new(-122, 45.5)]

  # CREATE Tracks USING THE TRACK Segments
  t = Track.new([ts1, ts2], "track 1")
  t2 = Track.new([ts3], "track 2")

  # CREATE A World CONTAINING NEW Waypoint AND Tracks
  world = World.new("My Data", [w, w2, t, t2])

  # OUTPUT geojson REPRESENTATION
  puts world.to_geojson
end

if __FILE__ == $0
  main
end
