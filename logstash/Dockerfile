ENV LOGSTASH_VERSION:{LOGSTASH_VERSION:-7.17.15}

FROM docker.elastic.co/logstash/logstash:${LOGSTASH_VERSION:-7.17.15}
RUN rm -f /usr/share/logstash/pipeline/logstash.conf
