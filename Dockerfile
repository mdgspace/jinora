FROM node:14.18 AS builder

RUN mkdir /jinora
WORKDIR /jinora/

COPY package.json package.json
COPY npm-shrinkwrap.json npm-shrinkwrap.json

COPY public public

RUN npm install --global coffeescript@1.12.7
RUN npm i

COPY . .

RUN ./node_modules/.bin/bower install --allow-root && ./node_modules/.bin/coffee -bc public/*.coffee

CMD ["coffee", "app.coffee"]
