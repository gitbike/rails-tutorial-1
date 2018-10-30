class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy]
  before_action :correct_user, only: :destroy

  def create
    @micropost = current_user.microposts.build(micropost_params)
    if @micropost.save
      flash[:success] = 'Micropost created!'
      redirect_to root_url
    else
      @feed_items = []
      render 'static_pages/home'
    end
  end

  def destroy
    @micropost.destroy
    flash[:success] = 'Micropost deleted.'
    redirect_back(fallback_location: root_url)
    # 13.3.4の演習で書き換えたメソッド
    # redirect_to request.referrer || root_url
  end

  private

    def micropost_params
      # params[:micropost][:content]とparams[:micropost][:picture]以外の値を送信不可にするためのStrong Parameters。Web経由ではMicropostモデルのcontent属性だけを変更可能にする。
      params.require(:micropost).permit(:content, :picture)
    end

    def correct_user
      @micropost = current_user.microposts.find_by(id: params[:id])
      redirect_to root_url if @micropost.nil?
    end
end
