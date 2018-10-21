class AddAdminToUsers < ActiveRecord::Migration[5.1]
  def change
    # Railsではboolea値はもともとデフォルトでnilはfalseになるので
    # { default: false }は必要ないが、他の開発者が分かりやすくなるので明示すると良い
    add_column :users, :admin, :boolean, default: false
  end
end
