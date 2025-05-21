# ruby-version-min: 1.8.7

# Main module
#
# This module gets evaluated immediately

process = import 'process'
log = import 'log'

# stage 1: gather context
context = import 'context'

log.info { "context: #{context.status.inspect}" }

# stage 2: check context against requirements
guard = import 'guard'

if (result = guard.call(context.status))
  log.info { "guard:call result:#{result.inspect}" }

  tags = result.map { |r| "reason:#{r[:reason]}" }

# stage 3: inject
else
  log.info { 'inject:proceed' }

  injector = import 'injector'

  injector.call
end
