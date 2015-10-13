class FlagSerializer < ActiveModel::Serializer
  attributes :longitude, :latitude, :radius
end
