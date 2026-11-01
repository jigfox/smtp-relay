FROM alpine:3.24.3

RUN apk update && apk upgrade && apk add postfix ca-certificates && rm -rf /var/cache/apk/*

EXPOSE 25/tcp
EXPOSE 465/tcp
EXPOSE 587/tcp

LABEL org.opencontainers.image.source="https://github.com/jigfox/smtp-relay"

COPY main.cf /etc/postfix/main.cf

COPY start.sh /start.sh

CMD ["sh", "/start.sh"]
