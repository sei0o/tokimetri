class SettingsController < ApplicationController
  def edit
    @setting = Setting.instance
  end

  def update
    @setting = Setting.instance
    if @setting.update(setting_params)
      redirect_to settings_url, notice: "設定を更新しました。"
    else
      render :edit, alert: "設定の更新に失敗しました。"
    end
  end

  private

  def setting_params
    params.require(:setting).permit(:prompt, :timezone, categories: [ :name, :color ])
  end
end
