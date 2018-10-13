require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  test 'Invalid signup information' do
    get signup_path
    assert_no_difference 'User.count' do
      post signup_path, params: { user: { name: '',
                                         email: 'user@invalid',
                                         password: 'foo',
                                         password_confirmation: 'bar' } }
    end
    assert_template 'users/new'
    assert_select 'div#error_explanation'
    assert_select 'div.alert'
    assert_select 'div.alert-danger'
    assert_select 'form[action="/signup"]'
  end

  test 'valid signup information' do
    get signup_path
    # 第2引数の「1」 はブロック内のコードを実行する前と後でデータベースのレコードが1増えていることを意味する
    assert_difference 'User.count', 1 do
      post users_path, params: { user: { name: 'Example User',
                                         email: 'user@example.com',
                                         password: 'password',
                                         password_confirmation: 'password' } }
    end
    follow_redirect!
    assert_template 'users/show'
    assert_select 'div.alert'
    assert_select 'div.alert-success'
    assert_not flash.empty?
    assert is_logged_in?
  end
end
