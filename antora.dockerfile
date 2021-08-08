FROM antora/antora:2.3.4
RUN yarn global add http-server onchange

# install build depdencies for pyspelling
RUN apk add --no-cache \
	bash build-base python3 python3-dev libxml2-dev libxslt-dev

# install pyspelling
RUN apk add aspell aspell-en
RUN pip3 install pyspelling

WORKDIR /site
