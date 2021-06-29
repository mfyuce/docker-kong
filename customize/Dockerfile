ARG KONG_BASE=kong-gateway:2.4.1.1-alpine
   
ARG PLUGINS
ENV INJECTED_PLUGINS=${PLUGINS}
 

ARG ROCKS_DIR=empty_file
ENV ROCKS_DIR=${ROCKS_DIR}
   
USER root

RUN apk add --no-cache luarocks 
RUN luarocks install "$INJECTED_PLUGINS"

USER root

#RUN /plugins/install_plugins.sh

HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health

USER kong

EXPOSE 8002 8445 8003

