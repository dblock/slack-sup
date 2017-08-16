# A single sup between multiple users.
class Sup
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :round
  has_and_belongs_to_many :users
  has_many :meetings, dependent: :destroy

  index(round: 1, user_ids: 1)

  after_create do
    users.each do |user|
      users.each do |other|
        next if other == user
        Meeting.create!(sup: self, user: user, other: other)
      end
    end
  end
end
