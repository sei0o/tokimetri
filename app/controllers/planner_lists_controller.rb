class PlannerListsController < ApplicationController
  before_action { @categories = Setting.instance.categories }

  def create
    PlannerList.create!(list_params(params.require(:planner_list)))
    redirect_to planner_everyday_path
  end

  def show
    @list = PlannerList.find(params[:id])
    @days = @list.records.includes(:page).where(pages: { date: (current_date - 8.weeks).. })
                 .order("pages.date DESC", :start_time).group_by(&:page)
  end

  def update
    list = PlannerList.find(params[:id])
    list.update!(params.require(:planner_list).permit(:note, planner_items_attributes: %i[id content condition]))
    redirect_to list
  end

  # 一覧はひとつのフォームで、書き換え・追加をまとめて受ける。名前を消すと削除
  def update_all
    PlannerList.transaction do
      params.fetch(:lists, {}).each do |id, attrs|
        list = PlannerList.find(id)
        attrs[:title].blank? ? list.destroy : list.update!(list_params(attrs))
      end

      new = list_params(params.fetch(:new, {}))
      PlannerList.create!(new) if new[:title].present?
    end

    redirect_to planner_everyday_path
  end

  private

  def list_params(attrs) = attrs.permit(:title, :category, :period, :estimate_minutes, wdays: [])
end
