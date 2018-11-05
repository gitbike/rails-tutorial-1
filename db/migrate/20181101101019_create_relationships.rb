class CreateRelationships < ActiveRecord::Migration[5.1]
  def change
    create_table :relationships do |t|
      t.integer :follower_id
      t.integer :followed_id

      t.timestamps
    end
    add_index :relationships, :follower_id
    add_index :relationships, :followed_id
    # あるユーザーが同じユーザーを2回以上フォローすることを防ぐための複合キー, curlなどのコマンドラインツールを使ってRelationshipのデータを直接操作することを防ぐ
    add_index :relationships, [:follower_id, :followed_id], unique: true
  end
end
