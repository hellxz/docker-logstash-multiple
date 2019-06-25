#/bin/bash
# just use this shell script to shutdown multiple logstash instance on the same machine.
cd ./logstash-01 && docker-compose down && \
cd ../logstash-02 && docker-compose down && \
cd ../logstash-03 && docker-compose down && \
cd ..
