FROM amazon/aws-cli:latest

RUN yum -y install bash curl inotify-tools && yum -y clean all  && rm -rf /var/cache

SHELL ["/bin/bash", "-eu", "-c"]
VOLUME /watch
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["entrypoint.sh"]
CMD ["NONE"]
