# Manyfold
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
[![All Contributors](https://img.shields.io/badge/all_contributors-41-orange.svg?style=flat-square)](#contributors-)
<!-- ALL-CONTRIBUTORS-BADGE:END -->

Manyfold is an open source, self-hosted web application for managing a collection of 3d models, particularly focused on 3d printing.

Visit [manyfold.app](https://manyfold.app/) for more details, installation instructions, and user and administration guides! Or, to have a go straight away, try our demo at [try.manyfold.app](https://try.manyfold.app).

## Help and Support

There are a few routes to get help:

* [GitHub issues](https://github.com/manyfold3d/manyfold/issues/new) is the best place to report bugs.
* [Live chat](https://matrix.to/#/#manyfold:matrix.org) to the "team" on Matrix (an open Discord/Slack-like chat system).
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
* [PostgreSQL](https://www.postgresql.org/) is the production database, though sqlite3 is used in dev

### Running locally

To run the app yourself, you'll need the following installed:

* Ruby 3.4
* Bundler 2.6+
* Node.js 22.15.1 (and run `corepack enable`)
* Yarn 3.8+
* Foreman or [another Procfile runner](https://github.com/ddollar/foreman#ports)
* [libarchive](https://github.com/chef/ffi-libarchive#installation) (for upload support)
* [imagemagick](https://imagemagick.org/index.php) (for image thumbnail generation)
* [ngrok](https://ngrok.com) (for ActivityPub development)
* [assimp](https://www.assimp.org) (for model file analysis)

To run the application once you've cloned this repo, you should be able to just run `bin/dev`; that should set up the database, perform migrations, install dependencies, and then make the application available at <http://127.0.0.1:5000>.

If you want to configure optional features, set the appropriate [environment variables](https://manyfold.app/sysadmin/configuration.html) in a file called `.env.development.local`. See `env.example` for a template file. Note that the required environment variables in the documentation are not needed in development mode, due to the use of SQLite instead of PostgreSQL.

#### ngrok

Running `bin/dev` also expects to be able to start a pre-configured [ngrok](https://ngrok.com) tunnel called "manyfold", to enable ActivityPub federation in development. If you don't want to use this, you can comment the line out of `Procfile.dev`, though please don't commit it!

To configure the tunnel, add this to your [ngrok config file](https://ngrok.com/docs/agent/config/):

```yaml
endpoints:
    - name: manyfold
      url: https://{your-ngrok-url-here}
      upstream:
         url: 5000
```

### Using the Devcontainer

To simplify the development environment setup, Manyfold includes a devcontainer configuration. This allows you to use Visual Studio Code's Remote - Containers extension to develop inside a container.

#### Prerequisites

- Docker installed on your machine
- Visual Studio Code with the Remote - Containers extension

#### Steps

1. Clone the repository:
    ```sh
    git clone https://github.com/manyfold3d/manyfold.git
    cd manyfold
    ```

2. Open the repository in Visual Studio Code:
    ```sh
    code .
    ```

3. When prompted by Visual Studio Code, click on "Reopen in Container". This will build the devcontainer and open the project inside it.

4. Once the container is running, you can use the integrated terminal in Visual Studio Code to run commands as usual.

### Coding standards

[![Codacy Quality](https://img.shields.io/codacy/grade/0d309b8b38b5431c9195e62cd7b707f3)](https://app.codacy.com/gh/manyfold3d/manyfold/dashboard)

We use [Rubocop](https://rubocop.org/) to monitor adherence to coding standards in Ruby code. We use [StandardRB](https://github.com/standardrb/standard) rules along with some other rulesets for specific libraries and frameworks.

You can run the linter with `bundle exec rubocop`.

We also have linters for ERB and Typescript files. You can run these with: `bundle exec erb_lint --lint-all` and `yarn run lint:ts` respectively.

Code linting is automatically performed by our GitHub Actions test runners, but if you set up [Husky](https://typicode.github.io/husky/get-started.html), it will also execute as a pre-commit hook.

### Testing

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/manyfold3d/manyfold/push.yml)
[![Codacy Coverage](https://img.shields.io/codacy/coverage/0d309b8b38b5431c9195e62cd7b707f3)](https://app.codacy.com/gh/manyfold3d/manyfold/dashboard)

We want to produce well-tested code; it's not 100%, but we aim to increase test coverage with each new bit of code.

You can run the test suite as a one off with the command `bundle exec rake`, or you can start a continuous test runner with `bundle exec guard` that will automatically run tests as you code.

Tests are run automatically when pushed to our repository using GitHub Actions.

Generation of screenshots for the documentation is made with system specs and is not run by default.
To generate screenshots, set `DOC_SCREENSHOT=true`:

```sh
# All specs and documentation
DOC_SCREENSHOT=true bundle exec rspec
# Only documentation specs
DOC_SCREENSHOT=true bundle exec rspec -t @documentation
```


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

## Contributors ✨

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://floppy.org.uk/"><img src="https://avatars.githubusercontent.com/u/3565?v=4?s=100" width="100px;" alt="James Smith"/><br /><sub><b>James Smith</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=Floppy" title="Code">💻</a> <a href="https://github.com/manyfold3d/manyfold/commits?author=Floppy" title="Tests">⚠️</a> <a href="#question-Floppy" title="Answering Questions">💬</a> <a href="#platform-Floppy" title="Packaging/porting to new platform">📦</a> <a href="#maintenance-Floppy" title="Maintenance">🚧</a> <a href="#infra-Floppy" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="#ideas-Floppy" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/manyfold3d/manyfold/commits?author=Floppy" title="Documentation">📖</a> <a href="https://github.com/manyfold3d/manyfold/issues?q=author%3AFloppy" title="Bug reports">🐛</a> <a href="#a11y-Floppy" title="Accessibility">️️️️♿️</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/matthewbadeau"><img src="https://avatars.githubusercontent.com/u/641764?v=4?s=100" width="100px;" alt="Matthew"/><br /><sub><b>Matthew</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=matthewbadeau" title="Code">💻</a> <a href="https://github.com/manyfold3d/manyfold/issues?q=author%3Amatthewbadeau" title="Bug reports">🐛</a> <a href="https://github.com/manyfold3d/manyfold/commits?author=matthewbadeau" title="Tests">⚠️</a> <a href="#promotion-matthewbadeau" title="Promotion">📣</a> <a href="#translation-matthewbadeau" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://oracleofthevoid.com/"><img src="https://avatars.githubusercontent.com/u/2481529?v=4?s=100" width="100px;" alt="Don Eisele"/><br /><sub><b>Don Eisele</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=ksuquix" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/mattpage"><img src="https://avatars.githubusercontent.com/u/732573?v=4?s=100" width="100px;" alt="Matthew Page"/><br /><sub><b>Matthew Page</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=mattpage" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/XioR112"><img src="https://avatars.githubusercontent.com/u/72562583?v=4?s=100" width="100px;" alt="XioR112"/><br /><sub><b>XioR112</b></sub></a><br /><a href="#translation-XioR112" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://experimentslabs.com/"><img src="https://avatars.githubusercontent.com/u/1732268?v=4?s=100" width="100px;" alt="Manuel Tancoigne"/><br /><sub><b>Manuel Tancoigne</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=mtancoigne" title="Tests">⚠️</a> <a href="https://github.com/manyfold3d/manyfold/commits?author=mtancoigne" title="Documentation">📖</a> <a href="#translation-mtancoigne" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/juanjomurga"><img src="https://avatars.githubusercontent.com/u/174307823?v=4?s=100" width="100px;" alt="juanjomurga"/><br /><sub><b>juanjomurga</b></sub></a><br /><a href="#translation-juanjomurga" title="Translation">🌍</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Mallo321123"><img src="https://avatars.githubusercontent.com/u/83690005?v=4?s=100" width="100px;" alt="Mallo321123"/><br /><sub><b>Mallo321123</b></sub></a><br /><a href="#translation-Mallo321123" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/TheMBeat"><img src="https://avatars.githubusercontent.com/u/21243082?v=4?s=100" width="100px;" alt="TheMBeat"/><br /><sub><b>TheMBeat</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=TheMBeat" title="Code">💻</a> <a href="https://github.com/manyfold3d/manyfold/commits?author=TheMBeat" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/fhp"><img src="https://avatars.githubusercontent.com/u/374671?v=4?s=100" width="100px;" alt="Stef Louwers"/><br /><sub><b>Stef Louwers</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=fhp" title="Code">💻</a> <a href="#translation-fhp" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://erbridge.co.uk/"><img src="https://avatars.githubusercontent.com/u/1027364?v=4?s=100" width="100px;" alt="F"/><br /><sub><b>F</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=erbridge" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Andreaj42"><img src="https://avatars.githubusercontent.com/u/59033540?v=4?s=100" width="100px;" alt="Andréa Joly"/><br /><sub><b>Andréa Joly</b></sub></a><br /><a href="#translation-Andreaj42" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Rukongai"><img src="https://avatars.githubusercontent.com/u/11468686?v=4?s=100" width="100px;" alt="Joseph R."/><br /><sub><b>Joseph R.</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=Rukongai" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/james-harder"><img src="https://avatars.githubusercontent.com/u/2560523?v=4?s=100" width="100px;" alt="james-harder"/><br /><sub><b>james-harder</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=james-harder" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://nyeprice.space/"><img src="https://avatars.githubusercontent.com/u/46961848?v=4?s=100" width="100px;" alt="Aneurin Price"/><br /><sub><b>Aneurin Price</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=aneurinprice" title="Code">💻</a> <a href="#a11y-aneurinprice" title="Accessibility">️️️️♿️</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://smcleod.net/"><img src="https://avatars.githubusercontent.com/u/862951?v=4?s=100" width="100px;" alt="Sam"/><br /><sub><b>Sam</b></sub></a><br /><a href="#platform-sammcj" title="Packaging/porting to new platform">📦</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/philstenning"><img src="https://avatars.githubusercontent.com/u/1886110?v=4?s=100" width="100px;" alt="Phil Stenning"/><br /><sub><b>Phil Stenning</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=philstenning" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://www.linkedin.com/in/andrewemauney/"><img src="https://avatars.githubusercontent.com/u/2627689?v=4?s=100" width="100px;" alt="Andrew Mauney"/><br /><sub><b>Andrew Mauney</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=chryton" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Daxx367"><img src="https://avatars.githubusercontent.com/u/3744006?v=4?s=100" width="100px;" alt="Max Connelly"/><br /><sub><b>Max Connelly</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=Daxx367" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/beniroquai"><img src="https://avatars.githubusercontent.com/u/4345528?v=4?s=100" width="100px;" alt="Benedict Diederich"/><br /><sub><b>Benedict Diederich</b></sub></a><br /><a href="#translation-beniroquai" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://www.richblox.nl/"><img src="https://avatars.githubusercontent.com/u/2945583?v=4?s=100" width="100px;" alt="Robin Rijkeboer"/><br /><sub><b>Robin Rijkeboer</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=Beagon" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/ToasterUwU"><img src="https://avatars.githubusercontent.com/u/43654377?v=4?s=100" width="100px;" alt="Aki"/><br /><sub><b>Aki</b></sub></a><br /><a href="#translation-ToasterUwU" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/mcsgroi"><img src="https://avatars.githubusercontent.com/u/8921172?v=4?s=100" width="100px;" alt="mcsgroi"/><br /><sub><b>mcsgroi</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=mcsgroi" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://www.fit.vut.cz/person/ichlubna/"><img src="https://avatars.githubusercontent.com/u/43234438?v=4?s=100" width="100px;" alt="Tomáš Chlubna"/><br /><sub><b>Tomáš Chlubna</b></sub></a><br /><a href="#translation-ichlubna" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://craftbeyondcode.com/"><img src="https://avatars.githubusercontent.com/u/253164?v=4?s=100" width="100px;" alt="Pedro Miguel Correia Araújo"/><br /><sub><b>Pedro Miguel Correia Araújo</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=pedromcaraujo" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/AevumDecessus"><img src="https://avatars.githubusercontent.com/u/1137023?v=4?s=100" width="100px;" alt="Siebren Bakker"/><br /><sub><b>Siebren Bakker</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=AevumDecessus" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://iamsaravieira.com/"><img src="https://avatars.githubusercontent.com/u/1051509?v=4?s=100" width="100px;" alt="Sara Vieira"/><br /><sub><b>Sara Vieira</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=SaraVieira" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/amethystdragon"><img src="https://avatars.githubusercontent.com/u/1350712?v=4?s=100" width="100px;" alt="amethystdragon"/><br /><sub><b>amethystdragon</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=amethystdragon" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/neographophobic"><img src="https://avatars.githubusercontent.com/u/2062699?v=4?s=100" width="100px;" alt="Adam Reed"/><br /><sub><b>Adam Reed</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=neographophobic" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/clepoittevin"><img src="https://avatars.githubusercontent.com/u/25842859?v=4?s=100" width="100px;" alt="Cédric Lepoittevin"/><br /><sub><b>Cédric Lepoittevin</b></sub></a><br /><a href="#translation-clepoittevin" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/jc43"><img src="https://avatars.githubusercontent.com/u/30440804?v=4?s=100" width="100px;" alt="jc43"/><br /><sub><b>jc43</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=jc43" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://mikecoats.com/"><img src="https://avatars.githubusercontent.com/u/37802088?v=4?s=100" width="100px;" alt="Mike Coats"/><br /><sub><b>Mike Coats</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/commits?author=MikeCoats" title="Code">💻</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/ZwiebelTVDE"><img src="https://avatars.githubusercontent.com/u/48917674?v=4?s=100" width="100px;" alt="ZwiebelTVDE"/><br /><sub><b>ZwiebelTVDE</b></sub></a><br /><a href="#translation-ZwiebelTVDE" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/Grecco-O"><img src="https://avatars.githubusercontent.com/u/48767181?v=4?s=100" width="100px;" alt="Petro"/><br /><sub><b>Petro</b></sub></a><br /><a href="https://github.com/manyfold3d/manyfold/issues?q=author%3AGrecco-O" title="Bug reports">🐛</a> <a href="#translation-Grecco-O" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/lucaj"><img src="https://avatars.githubusercontent.com/u/6617790?v=4?s=100" width="100px;" alt="lucaj"/><br /><sub><b>lucaj</b></sub></a><br /><a href="#translation-lucaj" title="Translation">🌍</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/EUSKR"><img src="https://avatars.githubusercontent.com/u/124172576?v=4?s=100" width="100px;" alt="euskr"/><br /><sub><b>euskr</b></sub></a><br /><a href="#translation-EUSKR" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/OlegEnot"><img src="https://avatars.githubusercontent.com/u/121382147?v=4?s=100" width="100px;" alt="olegenot"/><br /><sub><b>olegenot</b></sub></a><br /><a href="#translation-OlegEnot" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/sohanev"><img src="https://avatars.githubusercontent.com/u/188066793?v=4?s=100" width="100px;" alt="Soha"/><br /><sub><b>Soha</b></sub></a><br /><a href="#translation-sohanev" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://tablecheck.com/en/company"><img src="https://avatars.githubusercontent.com/u/803797?v=4?s=100" width="100px;" alt="Aleksandr T."/><br /><sub><b>Aleksandr T.</b></sub></a><br /><a href="#translation-terghalin" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/macdylan"><img src="https://avatars.githubusercontent.com/u/331506?v=4?s=100" width="100px;" alt="Dylan"/><br /><sub><b>Dylan</b></sub></a><br /><a href="#translation-macdylan" title="Translation">🌍</a></td>
    </tr>
  </tbody>
  <tfoot>
    <tr>
      <td align="center" size="13px" colspan="7">
        <img src="https://raw.githubusercontent.com/all-contributors/all-contributors-cli/1b8533af435da9854653492b1327a23a4dbd0a10/assets/logo-small.svg">
          <a href="https://all-contributors.js.org/docs/en/bot/usage">Add your contributions</a>
        </img>
      </td>
    </tr>
  </tfoot>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!

## Popularity

Down the bottom because they're cool, but not important, here are some stats!

[![Star History Chart](https://api.star-history.com/svg?repos=manyfold3d/manyfold&type=Date)](https://star-history.com/#manyfold3d/manyfold&Date)
