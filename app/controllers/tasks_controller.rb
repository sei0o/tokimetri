class TasksController < ApplicationController
  before_action { @categories = Setting.instance.categories }

  def index
    @today = current_date
    @inbox = Task.inbox(@today)
    @planned = Task.planned(@today)
  end

  def create
    task = Task.create!(params.require(:task).permit(:content, :date, :category).merge(position: Task.next_position))
    render partial: "tasks/plan_row", locals: { task: task }
  end

  def update
    Task.find(params[:id]).move(params[:to], current_date)
    head :ok
  end

  def destroy
    Task.find(params[:id]).destroy
    head :ok
  end

  # inbox ページはひとつのフォームで、書き換え・追加・移動をまとめて受ける
  def update_all
    Task.transaction do
      params.fetch(:tasks, {}).each do |id, attrs|
        task = Task.find(id)
        attrs[:content].blank? ? task.destroy : task.update!(attrs.permit(:content, :category))
      end

      params.fetch(:new, []).compact_blank.each do |content|
        Task.create!(content: content, position: Task.next_position)
      end

      params.fetch(:move, {}).each do |id, to|
        Task.find_by(id: id)&.move(to, current_date)
      end
    end

    redirect_to tasks_path
  end
end
