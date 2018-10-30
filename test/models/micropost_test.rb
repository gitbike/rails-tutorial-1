require 'test_helper'

class MicropostTest < ActiveSupport::TestCase
  def setup
    @user = users(:michael)
    @micropost = @user.microposts.build(content: 'Lorem ipsum')

    # 慣習的に正しくない書き方(belongs_to, has_manyを使っていないため、user_idを手動で設定している.上の慣習的に正しい書き方では規約に従い自動的に設定される)
    # @micropost = Micropost.new(content: 'Lorem ipsum', user_id: @user.id)
  end

  test 'should be valid' do
    # 正常な状態であるか(モデルのvalidatsで記述した制約に違反していないか)のテスト
    assert @micropost.valid?
  end

  test 'user id should be present' do
    # user_idがnullなら失敗しているかをテスト
    @micropost.user_id = nil
    assert_not @micropost.valid?
  end

  test 'content should be present' do
    @micropost.content = ' '
    assert_not @micropost.valid?
  end

  test 'content should be at most 140 characters' do
    @micropost.content = 'a' * 141
    assert_not @micropost.valid?
  end

  test 'order should be most resetnt first' do
    assert_equal microposts(:most_recent), Micropost.first
  end
end
