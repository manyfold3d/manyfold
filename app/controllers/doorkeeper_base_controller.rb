class DoorkeeperBaseController < ActionController::Base # rubocop:disable Rails/ApplicationController
  rate_limit to: 10, within: 3.minutes
end
