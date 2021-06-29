ARG KONG_BASE=kong/kong-gateway:2.4.1.1-alpine
   
FROM ${KONG_BASE} AS build

ARG PLUGINS
ENV INJECTED_PLUGINS=${PLUGINS}
 
USER root
 
RUN luarocks install kong-spec-expose

HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health

#USER kong

EXPOSE 8002 8445 8003

