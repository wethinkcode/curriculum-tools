FROM antora/antora:2.3.4
RUN yarn global add http-server onchange
WORKDIR /site
