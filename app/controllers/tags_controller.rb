class TagsController < ApplicationController
  def index
    @tags = ActsAsTaggableOn::Tag.all
  end
end
