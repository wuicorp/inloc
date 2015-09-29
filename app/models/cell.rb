class Cell
  include Mongoid::Document

  field :longitude, type: String
  field :latitude, type: String

  has_and_belongs_to_many :flags

  def find_or_create_flag_by(conditions = {})
    flags << Flag.find_or_create_by(conditions)
  end
end
