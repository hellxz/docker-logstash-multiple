#/bin/bash
# just use this shell script to start up multiple logstash instance on the same machine.
cd ./logstash-01 && docker-compose up -d && \
cd ../logstash-02 && docker-compose up -d && \
cd ../logstash-03 && docker-compose up -d && \
cd ..
