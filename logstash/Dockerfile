FROM docker.elastic.co/logstash/logstash:${LOGSTASH_VERSION:-7.17.15}
RUN rm -f /usr/share/logstash/pipeline/logstash.conf

VOLUME /var/lib/logstash/since-db
