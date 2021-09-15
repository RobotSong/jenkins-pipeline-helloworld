FROM java:8-alpine

# copy arthas
COPY --from=hengyunabc/arthas:latest /opt/arthas /opt/arthas

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV JAVA_OPTS="-Xmx512M -Xms256M -Xss256k -Duser.timezone=Asia/Shanghai"

ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS -jar /app.jar" ]
