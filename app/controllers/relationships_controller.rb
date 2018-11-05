class RelationshipsController < ApplicationController
  before_action :logged_in_user

  def create
    # Ajaxを使うために、ローカル変数userではなく、@userインスタンス変数に変更した
    @user = User.find(params[:followed_id])
    # ログインしていないときはnilを返すcurrent_userメソッドを使うことによって、ログインしていないユーザーがcurlなどのコマンドラインツールを使ってcreateやdestroyアクションにアクセスできないようにしている
    current_user.follow(@user)
    # respond_toメソッドは渡されたブロックの1行しか実行しないので、if文のような動作をする
    respond_to do |format|
      format.html { redirect_to @user }
      format.js
    end
  end

  def destroy
    @user = Relationship.find(params[:id]).followed
    current_user.unfollow(@user)
    respond_to do |format|
      format.html { redirect_to @user }
      format.js
    end
  end
end
