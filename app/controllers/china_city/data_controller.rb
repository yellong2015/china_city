require_dependency "china_city/application_controller"

module ChinaCity
  class DataController < ApplicationController
    def show
      data = ChinaCity.list(params[:id], postal_code: params[:postal_code])
      render json: data, layout: nil
    end

    def index
    end
  end
end
