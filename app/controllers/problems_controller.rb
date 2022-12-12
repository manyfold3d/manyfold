class ProblemsController < ApplicationController
  def index
    @problems = Problem.all
  end
end
