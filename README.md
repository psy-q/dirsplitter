dirsplitter
===========

Small script to split a directory containing many files into many subdirectories containing fewer files


### Usage

```
    dirsplit -l 254 -s source -d dest
```

Copies all files from directory `source` into subdirectories based on characters of the alphabet. The subdirectories are created underneath `dest`. See `--help` for more options.

Note that you probably have to run it from inside this source directory, like so:

```
    ./dirsplit -l 10 -s source -d dest
```

Otherwise it surely can't find its library. The library (in `lib/dirsplit.rb`) might be interesting for you if you ever want to use something like this in your own software. The thing is very, very, very primitive, but if you help out, we might be able to turn this into a nice little gem.

### Contributing

* Think of a feature to add.
* Fork the project to your own repo.
* Clone from your own repo.
* Run the test suite: `bundle exec rspec`
* Write a test for your new feature.
* Write your new feature.
* Make sure your test is green.
* Push to your repo and submit a pull request.

### Build status

Holy crap, it's a build status:

[![Build Status](https://travis-ci.org/psy-q/dirsplitter.png?branch=master)](https://travis-ci.org/psy-q/dirsplitter)
