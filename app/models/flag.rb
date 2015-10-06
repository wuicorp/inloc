class Flag
  include Mongoid::Document

  field :id, type: String

  belongs_to :flags_map
  has_and_belongs_to_many :cells

  before_destroy :destroy_related_cells

  def destroy_related_cells
    cells.each do |cell|
      cell.destroy if cell.flags.count == 1
    end
  end
end
