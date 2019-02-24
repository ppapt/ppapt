FROM registry.ott-consult.de/oc/liquibase:latest
LABEL MAINTAINER="joern.ott@ott-consult.de"

COPY src /


RUN /tmp/install/ppapt-liquibase.sh

USER liquibase:liquibase
ENTRYPOINT /entrypoint