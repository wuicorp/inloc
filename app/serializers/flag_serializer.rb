class FlagSerializer < ActiveModel::Serializer
  attributes :code, :longitude, :latitude, :radius
end
