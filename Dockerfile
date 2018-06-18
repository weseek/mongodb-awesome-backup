FROM alpine:3.7

LABEL maintainer="WESEEK <info@weseek.co.jp>"

RUN apk add --no-cache \
    coreutils \
    bash \
    tzdata \
    py2-pip \
    mongodb-tools \
    curl
RUN pip install awscli

# install dockerize(it is needed by e2e test)
ENV DOCKERIZE_VERSION v0.5.0
RUN curl -SL https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
      | tar -xz -C /usr/local/bin

# set timezone JST
RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

ENV AWS_DEFAULT_REGION=ap-northeast-1

COPY bin /opt/bin
WORKDIR /opt/bin
ENTRYPOINT ["/opt/bin/entrypoint.sh"]
CMD ["backup", "prune", "list"]
