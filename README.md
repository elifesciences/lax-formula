# `lax` formula

This repository contains instructions for installing and configuring the `lax`
project.

This repository should be structured as any Saltstack formula should, but it 
should also conform to the structure required by the [builder](https://github.com/elifesciences/builder) 
project.

This repository also contains a `Dockerfile` for local development.

See the eLife [builder example project](https://github.com/elifesciences/builder-example-project)
for a reference on how to integrate with the `builder` project.

## Reference

Run tests inside a local container with

```
git clone git@github.com/elifesciences/lax
docker build -t lax_dev .
docker run -it lax_dev ./project_tests.sh
```

Run a sample web server with
```
git clone git@github.com/elifesciences/lax
docker build -t lax_dev .
docker run -it -p 8000:8000 lax_dev bash ./manage.sh runserver 0.0.0.0:8000
```

## Copyright & Licence

Copyright 2016 eLife Sciences. Licensed under the [GPLv3](LICENCE.txt)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
