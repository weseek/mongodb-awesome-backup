FROM alpine:3.12

LABEL maintainer="WESEEK <info@weseek.co.jp>"

RUN apk add --no-cache \
    coreutils \
    bash \
    tzdata \
    py3-pip \
    mongodb-tools \
    curl

# install awscli
RUN pip install awscli

# install gcloud (also gsutil)
# ref: https://cloud.google.com/sdk/docs?hl=en#install_the_latest_cloud_tools_version_cloudsdk_current_version
ARG CLOUD_SDK_VERSION=299.0.0
ARG CLOUD_SDK_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz"
RUN curl $CLOUD_SDK_URL | tar xz -C $HOME
RUN $HOME/google-cloud-sdk/install.sh -q --path-update true

# set timezone JST
RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

ENV AWS_DEFAULT_REGION=ap-northeast-1

COPY bin /opt/bin
WORKDIR /opt/bin
ENTRYPOINT ["/opt/bin/entrypoint.sh"]
CMD ["backup", "prune", "list"]
