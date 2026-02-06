FROM alpine:latest

RUN apk update && apk upgrade && apk add postfix ca-certificates && rm -rf /var/cache/apk/*

EXPOSE 25/tcp
EXPOSE 465/tcp
EXPOSE 587/tcp

COPY main.cf /etc/postfix/main.cf

COPY start.sh /start.sh

CMD ["sh", "/start.sh"]
