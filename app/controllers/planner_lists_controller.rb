class PlannerListsController < ApplicationController
  def update
    list = PlannerList.find(params[:id])
    list.update!(params.require(:planner_list).permit(:note, :title, :category, :daily))
    request.media_type == "application/json" ? head(:ok) : redirect_back_or_to(planner_everyday_path)
  end
end
