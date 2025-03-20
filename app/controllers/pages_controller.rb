class PagesController < ApplicationController
  def index
    @pages = Page.all
  end

  def today
    @page = Page.find_by(date: Date.today)
    if @page.nil?
      @page = Page.new(date: Date.today)
      render :new
    else
      render :show
    end
  end
  
  def view
    require 'csv'
    @pages = Page.where.not(analyzed_content: nil)
  end

  def show
    @page = Page.find(params[:id])

    @yesterday = @page.date - 1.day
    @yesterday_page = Page.find_by(date: @yesterday)

    @tomorrow = @page.date + 1.day
    @tomorrow_page = Page.find_by(date: @tomorrow)
  end

  def graph
    @page = Page.find(params[:id])
  end

  def new
    @page = Page.new(date: params[:date])

    @yesterday = @page.date - 1.day
    @yesterday_page = Page.find_by(date: @yesterday)

    @tomorrow = @page.date + 1.day
    @tomorrow_page = Page.find_by(date: @tomorrow)
  end

  def create
    @page = Page.new(page_params)
    if @page.save
      redirect_to @page
    else
      render :new
    end
  end

  def edit
    @page = Page.find(params[:id])
  end

  def update
    @page = Page.find(params[:id])
    if @page.update(page_params)
      redirect_to @page
    else
      puts "fail"
      render :edit, status: :unprocessable_entity
    end
  end

  def analyze
    @page = Page.find(params[:id])
    if @page.analyze_and_update
      redirect_to @page
    else
      render :show
    end
  end

  def destroy
    @page = Page.find(params[:id])
    @page.destroy
    redirect_to pages_path
  end


  private
    def page_params
      params.expect(page: [ :date, :content ])
    end
end
