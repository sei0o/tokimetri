class PagesController < ApplicationController
  before_action :parse_and_set_date, only: [:show, :create, :update, :destroy, :analyze]
  before_action :set_page, only: [:show, :create, :update, :destroy, :analyze]
  before_action :set_navigation_pages, only: [:show]

  def index
    @pages = Page.all
  end

  def today
    redirect_to date_path(Date.today.strftime("%Y%m%d"))
  end

  def show
    if @page.persisted?
      render :show
    else
      render :new
    end
  end
  
  def view
    require 'csv'
    @pages = Page.where.not(analyzed_content: nil)
    @categories = Page::CATEGORIES
  end

  def create
    @page.assign_attributes(page_params)
    if @page.save
      redirect_to date_path(@date.strftime("%Y%m%d"))
    else
      set_navigation_pages
      render :new
    end
  end

  def update
    if @page.update(page_params)
      respond_to do |format|
        format.html { redirect_to date_path(@date.strftime("%Y%m%d")) }
        format.turbo_stream { 
          render turbo_stream: turbo_stream.update("editor-status", partial: "pages/save_status", locals: { status: "Saved" })
        }
      end
    else
      respond_to do |format|
        format.html { 
          set_navigation_pages
          render :show, status: :unprocessable_entity 
        }
        format.turbo_stream { 
          render turbo_stream: turbo_stream.update("editor-status", partial: "pages/save_status", locals: { status: "Error saving" })
        }
      end
    end
  end

  def analyze
    if @page.analyze_and_update
      redirect_to date_path(@date.strftime("%Y%m%d"))
    else
      set_navigation_pages
      render :show
    end
  end

  def destroy
    @page.destroy
    redirect_to pages_path
  end

  private

  def parse_and_set_date
    @date = Date.parse(params[:date])
  rescue Date::Error
    redirect_to today_path
  end

  def set_page
    @page = Page.find_by(date: @date) || Page.new(date: @date)
  end

  def set_navigation_pages
    return unless @date
    
    @yesterday = @date - 1.day
    @yesterday_page = Page.find_by(date: @yesterday)
    
    @tomorrow = @date + 1.day
    @tomorrow_page = Page.find_by(date: @tomorrow)
  end

  def page_params
    params.expect(page: [ :date, :content ])
  end
end
