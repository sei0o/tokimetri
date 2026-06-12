class PlannerItemsController < ApplicationController
  before_action :set_item, only: %i[update destroy]

  def create
    @list = PlannerList.find(params[:planner_list_id])
    @item = @list.planner_items.build(item_params)
    @item.position = @list.planner_items.maximum(:position).to_i + 1

    if @item.save
      render turbo_stream: [
        turbo_stream.append("list_#{@list.id}_items", partial: "planner/item", locals: { item: @item }),
        turbo_stream.replace("list_#{@list.id}_add_form", partial: "planner/add_form", locals: { list: @list })
      ]
    else
      head :unprocessable_entity
    end
  end

  def update
    if @item.update(item_params)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("item_#{@item.id}", partial: "planner/item", locals: { item: @item }) }
        format.json { head :ok }
      end
    else
      head :unprocessable_entity
    end
  end

  def destroy
    list = @item.planner_list
    @item.destroy
    render turbo_stream: turbo_stream.remove("item_#{@item.id}")
  end

  private

  def set_item
    @item = PlannerItem.find(params[:id])
  end

  def item_params
    params.require(:planner_item).permit(:content, :item_type, :condition, :duration_seconds)
  end
end
