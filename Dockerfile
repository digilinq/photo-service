FROM eclipse-temurin:21
WORKDIR /work
COPY photo-service.jar svc.jar
ENTRYPOINT ["java","-jar","svc.jar"]
