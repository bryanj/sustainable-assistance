class AssignmentsController < ApplicationController
  before_filter :set_variables
  def show
    @assignment = Assignment.find(params[:id])
  end

  def cheating
  end

  private
    def set_variables
      @assignments = Assignment.all
    end
end
