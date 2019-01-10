FROM python:2-slim

RUN apt-get update && apt-get install -yq git entr

WORKDIR /usr/src

COPY slides/requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

WORKDIR /usr/src/slides

VOLUME /usr/src

ENTRYPOINT ["./build.sh"]

CMD ["once"]