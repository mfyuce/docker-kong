ARG KONG_BASE=kong-gateway:2.4.1.1-alpine



FROM ${KONG_BASE} AS build

ARG PLUGINS
ENV INJECTED_PLUGINS=${PLUGINS}
     
COPY packer.lua /packer.lua

USER root

RUN /usr/local/openresty/luajit/bin/luajit /packer.lua -- "$INJECTED_PLUGINS"


FROM ${KONG_BASE}

COPY --from=build /plugins /plugins

USER root

RUN /plugins/install_plugins.sh

HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health

USER kong
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 8002 8445 8003

