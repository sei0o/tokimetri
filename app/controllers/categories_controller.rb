class CategoriesController < ApplicationController
  def show
    render plain: Record.guess_category(params[:what])
  end
end
