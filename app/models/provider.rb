class Provider < ApplicationRecord
  has_many :weather_readings

  # I know it's kind of an overkill in this case but can be useful thinking of a real application...
  scope :default, -> { first }
end
