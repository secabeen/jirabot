require 'sinatra/base'

module LSCGBot
  class Web < Sinatra::Base
    get '/' do
      'LSCGBot has issues. In a good way.'
    end
  end
end
