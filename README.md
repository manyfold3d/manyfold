# VanDAM

VanDAM is a Digital Asset Manager (DAM), specifically designed for 3D print files. Create a library pointing at your files on disk, and it will scan for models and parts. It assumes that any folders containing STL or OBJ files are models, and the files within them are parts. You can then view the files easily through your browser!

## Requirements

Ruby 3.x
Bundler 2.x

## Setup

```
bundle install
bundle exec rake db:migrate
bundle exec rails server
```

The server will then be running at http://127.0.0.1:3000
## How to run the test suite

`bundle exec rake`

## Credits

Built with [Rails 6](https://rubyonrails.org/) and [Three.js](https://threejs.org/). Source code is open under the MIT license at https://github.com/floppy/van_dam.
