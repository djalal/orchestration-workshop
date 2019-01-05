FROM python:2-slim

RUN apt-get update && apt-get install -yq git

WORKDIR /usr/src

COPY slides/requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

WORKDIR /usr/src/slides

RUN ["./build.sh", "once"]