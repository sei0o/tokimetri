class SavedSearchesController < ApplicationController
  def create
    SavedSearch.find_or_create_by!(query: params[:query])
    redirect_to search_path(q: params[:query])
  end

  def destroy
    SavedSearch.find(params[:id]).destroy
    redirect_to search_path
  end
end
