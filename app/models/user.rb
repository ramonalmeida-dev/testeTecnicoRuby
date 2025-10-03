class User < ApplicationRecord
  has_many :activities, dependent: :nullify

  validates :name, presence: true

  def to_s
    name
  end
end
