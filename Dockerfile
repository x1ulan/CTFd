FROM python:3.9-slim-buster
WORKDIR /opt/CTFd
RUN mkdir -p /opt/CTFd /var/log/CTFd /var/uploads

RUN sed -i "s@http://deb.debian.org@http://mirrors.aliyun.com@g" /etc/apt/sources.list

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libffi-dev \
        libssl-dev \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /opt/CTFd/

RUN pip install -r requirements.txt --no-cache-dir -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com

COPY . /opt/CTFd

ENV token=$(echo /dev/urandom | head | sha1sum)
RUN echo "token = ${TOKEN}" >> /opt/CTFd/conf/frp/frpc.ini
RUN echo "token = ${TOKEN}" >> /opt/CTFd/conf/frp/frps.ini
RUN sed -i "66c $(cat patch.txt)" /opt/CTFd/CTFd/plugins/ctfd-whale/assets/view.js

# hadolint ignore=SC2086
RUN for d in CTFd/plugins/*; do \
        if [ -f "$d/requirements.txt" ]; then \
            pip install -r $d/requirements.txt --no-cache-dir -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com; \
        fi; \
    done;

# hadolint ignore=DL3059
RUN adduser \
    --disabled-login \
    -u 1001 \
    --gecos "" \
    --shell /bin/bash \
    ctfd \
    && chmod +x /opt/CTFd/docker-entrypoint.sh \
    && chown -R 1001:1001 /opt/CTFd /var/log/CTFd /var/uploads

USER 1001
EXPOSE 8000
ENTRYPOINT ["/opt/CTFd/docker-entrypoint.sh"]
