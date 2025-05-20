# Datadog Ruby Injector

A specialized Ruby library designed to inject Datadog monitoring capabilities into Ruby applications with minimal impact and maximum compatibility across different Ruby environments.

## Overview

The Datadog Ruby Injector is an unusual Ruby project that allows injecting telemetry and tracing capabilities into Ruby applications, engineered to be compatible with a wide range of Ruby versions (1.8.7 and newer) and implementations (including JRuby).

## What Makes This Project Unusual

This project differs from conventional Ruby applications:

1. **Custom Module System**: Instead of using Ruby's standard `require` mechanism, it implements a custom import system that creates isolated modules for each file to avoid any global namespace pollution.

2. **Broad Version Compatibility**: Designed to work with CRuby 1.8.7 to 3.4, as well as JRuby 9.2 to 9.4.

3. **Zero Global Footprint**: The injector is carefully designed to avoid creating any global variables or constants, making it completely unintrusive to the host application. Once the injection is done, most - ideally all - of it will be unreferenced and garbage-collected.

4. **No Gem Packaging**: Unlike most Ruby libraries that are packaged as gems, the injector is designed for direct inclusion via Ruby's `-r` option.

5. **Rich Testing Matrix**: The test suite uses a sophisticated matrix approach to test across the whole matrix of Ruby environments, bundler configurations, and application scenarios very quickly.

## Features

- Automatic detection of the Ruby runtime environment
- Safe injection mechanics with guards to prevent incompatible injections
- Telemetry emission for monitoring the injection process
- Support for various Ruby runtime contexts including Bundler-managed environments
- Compatibility with deployment, frozen, and hot (development-like) environments

## Requirements

- Ruby (MRI) version 1.8.7 or newer, or JRuby 9.2+
- For test running: docker
- For development: Nix package manager (project uses flakes)

## Usage

The injector is typically loaded via Ruby's `-r` option:

```
ruby -r/path/to/datadog-injector-rb/src/injector.rb your_application.rb
```

Note: Best behaviour is only guaranteed when the injector is loaded _first_.

Alternatively, using the `RUBYOPT` environment variable makes use of the injector automatic:

```
export RUBYOPT="-r/path/to/datadog-injector-rb/src/injector.rb"

# run as usual
ruby your_application.rb

# or using bundler
bundle exec ruby your_application.rb
```

## Project Structure

- `/src`: Contains the main injector code
  - `injector.rb`: Entry point for the library
  - `/mod`: Module files that provide the core functionality
- `/test`: Test fixtures and utilities
  - `/fixtures`: Different application environments for testing
  - `/unit`: Unit tests
  - `test.rb`: Main test runner

## Running Tests

The test suite is designed to validate the injector's behavior across multiple Ruby environments and application configurations. The testing framework employs a comprehensive test matrix approach to verify compatibility across different scenarios.

There are two kind of tests:

- Unit Tests: narrow and focused on strict, detailed guarantees
- Component Tests: behaviour oriented, aims to validate component contract

### Test Matrix

The test matrix evaluates the injector against:

- **Ruby Implementations**: MRI Ruby (1.8.7 through 3.4) and JRuby (9.2 through 9.4)
- **Environment Types**:
  - `hot`: Standard Bundler environment
  - `deployment`: Bundler deployment mode
  - `frozen`: Bundler with frozen dependencies
  - `unbundled`: Ruby environment without Bundler

### Running Tests

To run the full test suite:

```bash
ruby test.rb
```

To run specific tests (TODO):

```bash
# Run tests for a specific Ruby version
ruby test.rb "ruby:2.7"

# Run tests for a specific fixture
ruby test.rb "fixture:hot"

# Run tests for a specific combination
ruby test.rb "ruby:2.7 fixture:hot"
```

### Test Fixtures

The `/test/fixtures` directory contains different application environments used for testing:

- `hot`: Standard Bundler environment with a Gemfile
- `deployment`: Tests against Bundler deployment mode
- `frozen`: Tests with Bundler's frozen dependencies
- `unbundled`: Tests without Bundler integration (no Gemfile)

### Test Output

Test results show telemetry events and injection status for each scenario, validating:

1. Proper startup detection (`telemetry should include start`)
2. Correct decision-making based on the environment (proceed or abort)
3. Proper reason codes for abort when applicable
4. Successful completion in compatible environments

## Development

This project optionally uses Nix for simple development environment management. To set up a development environment:

1. [Install Nix](https://nixos.org/download/) if you haven't already
2. Run `nix develop` (or its older incantation `nix-shell`)

## License

Copyright (c) Datadog, Inc. See `LICENSE` file.
