FROM python:3.10-slim-buster

WORKDIR /app

COPY . /app

RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]

EXPOSE ${PORT}
