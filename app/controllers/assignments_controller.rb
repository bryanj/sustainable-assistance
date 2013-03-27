class AssignmentsController < ApplicationController
  before_filter :set_variables
  def show
    @assignment = Assignment.find(params[:id])
    @period = Period.where(assignment_id: @assignment.id).where(["end_time > ?", Time.now]).first
  end

  def cheating
  end

  private
    def set_variables
      @assignments = Assignment.all
    end
end
