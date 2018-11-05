class Relationship < ApplicationRecord
  # active_relationshipインスタンスがactive_relationship.follewerメソッドを使えるようにするためのコード（表14.1）
  belongs_to :follower, class_name: 'User'
  belongs_to :followed, class_name: 'User'
  validates :follower_id, presence: true
  validates :followed_id, presence: true
end
