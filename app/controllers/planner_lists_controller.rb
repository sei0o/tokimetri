class PlannerListsController < ApplicationController
  def update
    list = PlannerList.find(params[:id])
    list.update!(note: params[:planner_list][:note])
    head :ok
  end
end
