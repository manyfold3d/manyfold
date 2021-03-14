# VanDAM

VanDAM is a Digital Asset Manager (DAM), specifically designed for 3D print
files. Create a library pointing at your files on disk, and it will scan for
models and parts. It assumes that any folders containing STL or OBJ files are
models, and the files within them are parts. You can then view the files easily
through your browser!

![preview](https://i.imgur.com/x5eYc15.jpg)

## Running in Docker

You can run the latest release in docker by using the image
`ghcr.io/floppy/van_dam:latest`. The app also needs a PostgreSQL and Redis
database to operate.

The docker image supports `linux/amd64`, `linux/arm/v7` and `linux/arm64`
architectures, so you should be able to run it on a PC, a Raspberry Pi, or an M1
Mac.

You can run all the dependencies in one go using `docker-compose`:

1. Copy `docker-compose.example.yml` to `docker-compose.yml` and edit the paths,
   secret key, and database password

2. Run `docker-compose up`

   This might fail the first time it's run due to race conditions in setting up
   the database.

3. Open Van DAM at http://localhost:3214

4. Add a library

   Remember the path mappings in the Docker Compose file? In
   `docker-compose.example.yml` the libraries at `/path/to/your/libraries` in
   your file system would be available at `/libraries` in the app.

## Development

### Requirements

- Ruby 3.x
- Bundler 2.x
- Node.js 14.x
- Yarn >= 1.22
- Foreman or [another Procfile runner](https://github.com/ddollar/foreman#ports)

### Usage

```
bundle install
yarn install
bundle exec rake db:migrate
foreman start
```

The server will then be running at http://127.0.0.1:5000

### How to run the test suite

`bundle exec rake`

## Credits

Built with [Rails 6](https://rubyonrails.org/) and
[Three.js](https://threejs.org/). Source code is open under the MIT license at
https://github.com/floppy/van_dam.
