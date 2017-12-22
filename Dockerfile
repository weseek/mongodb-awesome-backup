FROM alpine:3.7

LABEL maintainer="WESEEK <info@weseek.co.jp>"

RUN apk add --no-cache \
    coreutils \
    bash \
    py2-pip \
    mongodb-tools
RUN pip install awscli

ENV AWS_DEFAULT_REGION=ap-northeast-1

COPY . /opt/bin
WORKDIR /opt/bin
ENTRYPOINT ["/opt/bin/entrypoint.sh"]
CMD ["backup", "prune", "list"]
