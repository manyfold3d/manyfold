# Manyfold

Manyfold is an open source, self-hosted web application for managing a collection of 3d models, particularly focused on 3d printing.

Visit [manyfold.app](https://manyfold.app/) for more details, installation instructions, and user and administration guides! Or, to have a go straight away, try our demo at [try.manyfold.app](https://try.manyfold.app).

## Help and Support

There are a few routes to get help:

* [GitHub issues](https://github.com/manyfold3d/manyfold/issues/new) is the best place to report bugs.
* [Live chat](https://matrix.to/#/#manyfold:one.ems.host) to the "team" on Matrix (an open Discord/Slack-like chat system).
* Get in touch with our [social media](https://3dp.chat/@manyfold) presence in the Fediverse (Mastodon, etc).

And, if you want to contribute financially to development efforts...

[<img src="https://opencollective.com/manyfold/donate/button@2x.png?color=blue" alt="Donate with OpenCollective" width="20%" />](https://opencollective.com/manyfold/donate)

## Developer Documentation

Manyfold is open source software, and we encourage contributions! If you want to get involved, follow the guidance below, which explains how to get up and running. Then take a look at our [good first issue](https://github.com/manyfold3d/manyfold/labels/good%20first%20issue) tag for tasks that might suit newcomers to the codebase, or take a look at our [development roadmap](https://github.com/orgs/manyfold3d/projects/1).

### Application architecture

The application is built in [Ruby on Rails](https://rubyonrails.org), and tries to follow the best practices of that framework wherever possible. If you're not familiar with Rails, their [Getting Started](https://guides.rubyonrails.org/getting_started.html) guide is a good first introduction.

In general, Manyfold is a server-side app that uses plain old HTTP requests. We don't have any code using XHR, Websockets, or other more interactive comms yet (though could do in future).

The application consists of the application server itself, plus a background job runner using [Sidekiq](https://sidekiq.org/) for asynchronous tasks.

There are a few other major components that we build with:

* [Bootstrap 5](https://getbootstrap.com) provides the frontend CSS / JS
* [THREE.js](https://threejs.org/) (via TypeScript) is used for the client-side 3D rendering
* [Mittsu](https://github.com/danini-the-panini/mittsu), a Ruby port of THREE.js, is used for server-side 3D code
* [ActiveAdmin](https://activeadmin.info/) is used for now to provide an advanced database admin interface
* [PostgreSQL](https://www.postgresql.org/) is the production database, though sqlite3 is used in dev

### Running locally

To run the app yourself, you'll need the following installed:

* Ruby 3.2
* Bundler 2.x
* Node.js 20.x
* Yarn >= 1.22
* Foreman or [another Procfile runner](https://github.com/ddollar/foreman#ports)
* [libarchive](https://github.com/chef/ffi-libarchive#installation) (for upload support)
* [glfw3](https://github.com/danini-the-panini/mittsu#installation) (for model analysis & manipulation)

To run the application once you've cloned this repo, you should be able to just run `bin/dev`; that should set up the database, perform migrations, install dependencies, and then make the application available at <http://127.0.0.1:5000>.

If you want to configure optional features, set the appropriate [environment variables](https://manyfold.app/sysadmin/configuration.html) in a file called `.env`. See `env.example` for a template file. Note that the required environment variables in the documentation are not needed in development mode, due to the use of SQLite instead of PostgreSQL.

### Coding standards

![Code Climate maintainability](https://img.shields.io/codeclimate/maintainability/manyfold3d/manyfold)
![Code Climate technical debt](https://img.shields.io/codeclimate/tech-debt/manyfold3d/manyfold)

We use [Rubocop](https://rubocop.org/) to monitor adherence to coding standards in Ruby code. We use [StandardRB](https://github.com/standardrb/standard) rules along with some other rulesets for specific libraries and frameworks.

You can run the linter with `bundle exec rubocop`.

We also have linters for ERB and Typescript files. You can run these with: `bundle exec erb_lint --lint-all` and `yarn run lint:ts` respectively.

Code linting is automatically performed by our GitHub Actions test runners, but if you set up [Husky](https://typicode.github.io/husky/get-started.html), it will also execute as a pre-commit hook.

### Testing

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/manyfold3d/manyfold/push.yml)
![Code Climate coverage](https://img.shields.io/codeclimate/coverage/manyfold3d/manyfold)

We want to produce well-tested code; it's not 100%, but we aim to increase test coverage with each new bit of code.

You can run the test suite as a one off with the command `bundle exec rake`, or you can start a continuous test runner with `bundle exec guard` that will automatically run tests as you code.

Tests are run automatically when pushed to our repository using GitHub Actions.

### Internationalisation & Translation

Manyfold uses [Rails' I18n framework](https://guides.rubyonrails.org/i18n.html) to handle all text content.

You can check the validity of locale files with `bundle exec i18n-tasks health`. This is also run as part of our test pipeline, so will be enforced on new code.

Translations are also available in client-side Javascript; they are built from the Rails locale files as part of the asset pipeline, using [i18n-js](https://github.com/fnando/i18n-js). If you need to run an export manually, do `bundle exec i18n export -c config/i18n-js.yml`.

We are using [Translation.io](https://translation.io/) to manage translations into other languages. If you want to help out on that, sign up on the site and send us username on a GitHub issue for the language you're interested in.

To synchronise with Translation.io, run `rake translation:clobber_and_sync:{locale}` where `{locale}` is a supported code, such as `de`.

### Building Docker images

[![Built with Depot](https://depot.dev/badges/built-with-depot.svg)](https://depot.dev?utm_source=manyfold)

The application is distributed as a multi-platform docker image (built by [Depot](https://depot.dev/)); see our [Docker Compose instructions](https://manyfold.app/get-started/docker) for full details.

If you want to build your own version of the Docker image, you can do so by running ` docker build -f docker/default.dockerfile .` in the root directory of this repository.

## Funding

This project is funded through [NGI0 Entrust](https://nlnet.nl/entrust), a fund established by [NLnet](https://nlnet.nl) with financial support from the European Commission's [Next Generation Internet](https://ngi.eu) program. Learn more at the [NLnet project page](https://nlnet.nl/project/Personal-3D-archive).

[<img src="https://nlnet.nl/logo/banner.png" alt="NLnet foundation logo" width="20%" />](https://nlnet.nl)
[<img src="https://nlnet.nl/image/logos/NGI0_tag.svg" alt="NGI Zero Logo" width="20%" />](https://nlnet.nl/entrust)

This project is also funded by you! Make a donation to support long-term development at OpenCollective:

[<img src="https://opencollective.com/manyfold/donate/button@2x.png?color=blue" alt="Donate with OpenCollective" width="20%" />](https://opencollective.com/manyfold/donate)

## Popularity

Down the bottom because they're cool, but not important, here are some stats!

[![Star History Chart](https://api.star-history.com/svg?repos=manyfold3d/manyfold&type=Date)](https://star-history.com/#manyfold3d/manyfold&Date)
