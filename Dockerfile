FROM  alpine:3.7
LABEL maintainer="Myros <myros.net@gmail.com>"

RUN set -ex \
    \
  && apk add --no-cache --virtual .fetch-deps \
	   curl dcron wget rsync ca-certificates mysql-client \
  && curl -L https://github.com/odise/go-cron/releases/download/v0.0.7/go-cron-linux.gz | zcat > /usr/local/bin/go-cron \
	&& chmod a+x /usr/local/bin/go-cron \
	&& rm -rf /var/cache/apk/*

RUN apk add --update \
    python \
    python-dev \
    py-pip \
    build-base \
  && pip install awscli \
  && rm -rf /var/cache/apk/*

VOLUME /backups

ADD s3cfg /root/.s3cfg

ENV SCHEDULE="@daily"

# entrypoint
ADD entrypoint.sh /entrypoint.sh

ADD run.sh run.sh
ADD backup.sh backup.sh

RUN chmod +x /backup.sh

CMD ["sh", "run.sh"]

HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost/ || exit 1
