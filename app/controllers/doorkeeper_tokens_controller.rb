class DoorkeeperTokensController < Doorkeeper::TokensController
  rate_limit to: 10, within: 3.minutes
end
