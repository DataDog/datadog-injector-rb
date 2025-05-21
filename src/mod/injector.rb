# ruby-version-min: 1.8.7

LOG = import 'log'

class << self
  def call
    LOG.info { 'injector:call' }
  end
end

