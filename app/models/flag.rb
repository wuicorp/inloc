class Flag
  include Mongoid::Document

  field :application_id, type: String
  field :longitude, type: BigDecimal
  field :latitude, type: BigDecimal
  field :radius, type: Integer

  has_and_belongs_to_many :cells

  before_save :detach_cells
  after_save :attach_cells
  before_destroy :detach_cells

  validates_numericality_of :longitude, :latitude, :radius
  validates_presence_of :application_id, :longitude, :latitude, :radius

  scope :for_application_id, -> id { where(application_id: id) }

  def detach_cells
    cells.each { |c|
      c.destroy if c.flags.count == 1
    }

    cells.clear
  end

  def attach_cells
    Cell.cells_for(longitude, latitude, radius) do |cell|
      cells << cell
    end
  end
end
