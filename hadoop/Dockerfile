FROM eclipse-temurin:8-jdk-jammy
ADD pseudo_hadoop285.sh /
RUN bash /pseudo_hadoop285.sh
# ports:
#   22   SSH
#   8032 ResourceManager
#   8088 Web interface for YARN ResourceManager.
#   9000 nameNode
EXPOSE 22 9000 8032 8088
