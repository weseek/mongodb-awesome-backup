FROM alpine:3.7

LABEL maintainer="WESEEK <info@weseek.co.jp>"

RUN apk add --no-cache \
    coreutils \
    bash \
    tzdata \
    py2-pip \
    mongodb-tools \
    curl

# install awscli
RUN pip install awscli

# install gcloud (also gsutil)
ARG GCLOUD_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-245.0.0-linux-x86_64.tar.gz?hl=ja
RUN curl $GCLOUD_URL | tar xz -C $HOME
RUN $HOME/google-cloud-sdk/install.sh -q --path-update true

# set timezone JST
RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

ENV AWS_DEFAULT_REGION=ap-northeast-1

COPY bin /opt/bin
WORKDIR /opt/bin
ENTRYPOINT ["/opt/bin/entrypoint.sh"]
CMD ["backup", "prune", "list"]
