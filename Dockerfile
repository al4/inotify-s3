# awscli must run on python 3.7
FROM python:3.7-alpine

LABEL org.opencontainers.image.authors="@infra"
LABEL org.opencontainers.image.channel="#eng-infrastructure"
LABEL org.opencontainers.image.title="inotify-s3"
LABEL org.opencontainers.image.type="alpine"
LABEL org.opencontainers.image.release_method="manual+environments"

RUN apk upgrade --no-cache
RUN apk add --no-cache ca-certificates groff bash curl inotify-tools
RUN pip install awscli

SHELL ["/bin/bash", "-eu", "-c"]
VOLUME /watch
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["entrypoint.sh"]
CMD ["NONE"]
