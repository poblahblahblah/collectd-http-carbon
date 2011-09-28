require 'worker'

use Rack::ShowExceptions
run Worker.new
