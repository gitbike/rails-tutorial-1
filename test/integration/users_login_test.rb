require 'test_helper'

class UsresLoginTest < ActionDispatch::IntegrationTest
  def setup
    # usersはtest/fixtures/users.ymlを使うためのメソッド
    @user = users(:michael)
  end

  test 'login with valid information followd by logout' do
    get login_path
    post login_path, params: { session: { email: @user.email,
                                          password: 'password' } }
    assert is_logged_in?
    assert_redirected_to @user
    follow_redirect!
    assert_template 'users/show'
    assert_select 'a[href=?]', login_path, count: 0
    assert_select 'a[href=?]', logout_path
    assert_select 'a[href=?]', user_path(@user)
    delete logout_path # DELETEリクエストをlogout用パスに発行(セッションの削除＝ログアウト)
    assert_not is_logged_in?
    assert_redirected_to root_url

    # 複数タブでのログアウトをテストするため、2番目のタブでログアウトするユーザーのシミュレート
    delete logout_path

    follow_redirect!
    assert_select 'a[href=?]', login_path
    assert_select 'a[href=?]', logout_path, count: 0
    assert_select 'a[href=?]', user_path(@user), count: 0
  end

  test 'login with invalid information' do
    get login_path
    assert_template 'sessions/new'
    post login_path, params: { session: { email: '', password: '' } }
    assert_template 'sessions/new'
    assert_not flash.empty?
    get root_path
    assert flash.empty?
  end

  test 'login with remembering' do
    log_in_as(@user, remember_me: '1')
    # テスト内ではcookiesメソッドにシンボルは使えないので'remember_token'と文字列で呼び出している
    assert_equal cookies['remember_token'], assigns(:user).remember_token
  end

  test 'login without remembering' do
    log_in_as(@user, remember_me: '1')
    delete logout_path
    log_in_as(@user, remember_me: '0')
    assert_empty cookies['remember_token']
  end
end
