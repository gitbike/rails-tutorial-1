module SessionsHelper
  # ApplicationControllerがincludeしているので、ここのヘルパーメソッドは全てのビューで使える

  # user.idから一時的なクッキー(ブラウザを閉じると消える)を生成するためにRailsのsessionメソッドを使う
  def log_in(user)
    session[:user_id] = user.id
  end

  # DBへのアクセスを最初の1回だけにするためのメモイゼーション
  def current_user
    if session[:user_id]
      @current_user = User.find_by(id: session[:user_id])
    end
  end

  # ログインしているかどうかでヘッダーの項目を変えられるようにするために追加したメソッド
  def logged_in?
    !current_user.nil?
  end

  # deleteだけでも現在のユーザーはnilになるが、安全性を高めたいので、念のため@current_userもnilにしておく
  def log_out
    session.delete(:user_id)
    @current_user = nil
  end
end
