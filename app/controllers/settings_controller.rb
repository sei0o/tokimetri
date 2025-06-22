class SettingsController < ApplicationController
  def edit
    @setting = Setting.instance
  end

  def update
    @setting = Setting.instance
    if @setting.update(setting_params)
      redirect_to edit_settings_path, notice: "設定を更新しました"
    else
      render :edit
    end
  end

  private

  def setting_params
    params.require(:setting).permit(:enable_feature_x, :max_items, :theme)
  end
end
