class ProjectsController < ApplicationController
  before_action { @categories = Setting.instance.categories }

  def index
    @projects = Project.order(:name)
  end

  def show
    @project = Project.find(params[:id])
    @days = @project.records.includes(:page).order("pages.date DESC", :start_time).group_by(&:page)
  end

  def update
    project = Project.find(params[:id])
    project.update!(params.require(:project).permit(:note)) if params[:project]
    project.records.where(id: params[:remove]).update_all(project_id: nil) if params[:remove]
    redirect_to project
  end

  # 一覧はひとつのフォームで、書き換え・追加をまとめて受ける。名前を消すと削除
  def update_all
    Project.transaction do
      params.fetch(:projects, {}).each do |id, attrs|
        project = Project.find(id)
        attrs[:name].blank? ? project.destroy : project.update!(attrs.permit(:name, :category, :query))
      end

      new = params.fetch(:new, {}).permit(:name, :category, :query)
      Project.create!(new) if new[:name].present?
    end

    redirect_to projects_path
  end

  # 検索画面から。いま検索している語をフィルタに足すか、選んだ行を入れる
  def terms
    project = Project.find(params[:project_id])
    project.add_term(params[:term])
    redirect_to project
  end

  def records
    project = Project.find(params[:project_id])
    project.add(Record.activities.where(id: params[:record_ids]))
    redirect_to project
  end
end
