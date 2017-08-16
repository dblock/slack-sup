# A single sup between multiple users.
class Meeting
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  belongs_to :sup
  belongs_to :user
  belongs_to :other, class_name: 'User', inverse_of: nil

  index(sup_id: 1, user_id: 1, other_id: 1, created_at: 1)
end
