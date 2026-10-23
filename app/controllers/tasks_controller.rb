class TasksController < ApplicationController
  before_action { @categories = Setting.instance.categories }

  # 今日から1週間は空でも日ごとに見せる。過ぎた日のものは週に戻して見せる
  def index
    @today = current_date
    @inbox = Task.inbox(@today)
    dated, undated = Task.planned(@today).partition { _1.date && _1.date >= @today }
    @days = (@today..@today + 6.days).to_h { [ _1, [] ] }.merge(dated.group_by(&:date))
    @this_week, later = undated.partition { _1.week == @today.beginning_of_week }
    @weeks = later.group_by(&:week)
    @projects = Project.order(:name)
    @disposable = DisposableTime.new(@today, current_time)
  end

  def create
    task = Task.create!(params.require(:task).permit(:content, :date, :category, :estimate_minutes, :project_id).merge(position: Task.next_position))
    return redirect_to task.project if params[:from] == "project"

    render partial: "tasks/plan_row", locals: { task: task }
  end

  # log の plan から。日への移動か、欄の書き換え
  def update
    task = Task.find(params[:id])
    if params[:to]
      task.move(params[:to], current_date)
      head :ok
    else
      head task.update(params.require(:task).permit(:content, :estimate_minutes, :category)) ? :ok : :unprocessable_entity
    end
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
        attrs[:content].blank? ? task.destroy : task.update!(attrs.permit(:content, :category, :estimate_minutes, :project_id))
      end

      new = params.fetch(:new, {}).permit(:content, :category, :estimate_minutes, :project_id)
      Task.create!(new.merge(position: Task.next_position)) if new[:content].present?

      params.fetch(:move, {}).each do |id, to|
        Task.find_by(id: id)&.move(to, current_date) if to.present?
      end
    end

    redirect_to tasks_path
  end
end
