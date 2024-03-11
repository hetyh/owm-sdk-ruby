module OwmSdk
  module Errors
    class Error < StandardError; end

    class RequestError < StandardError; end

    class ServerError < StandardError; end
  end
end
