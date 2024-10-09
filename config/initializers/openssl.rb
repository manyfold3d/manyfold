# Ignore OpenSSL EOF errors that are very common with OpenSSL 3 because the Internet is terrible.
# This solution is a horrible hack from https://stackoverflow.com/questions/76183622/since-a-ruby-container-upgrade-we-expirience-a-lot-of-opensslsslsslerror
# but it seems the quickest and most global solution without rewriting a bunch of lower-level code.
# It'll do for now.
OpenSSL::SSL::SSLContext::DEFAULT_PARAMS = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS.merge(
  options: OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options] + OpenSSL::SSL::OP_IGNORE_UNEXPECTED_EOF
).freeze
