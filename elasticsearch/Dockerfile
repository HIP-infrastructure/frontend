ARG ELASTICSEARCH_VERSION=7.17.0
FROM docker.elastic.co/elasticsearch/elasticsearch:${ELASTICSEARCH_VERSION}

RUN export
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch ingest-attachment
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y tesseract-ocr tesseract-ocr-deu tesseract-ocr-eng && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
