FROM node:24.14.0-bookworm-slim AS build

WORKDIR /workspace/app

COPY app/package*.json ./
RUN npm ci --omit=dev

COPY app ./
RUN mkdir -p /var/log/devops-app

FROM gcr.io/distroless/nodejs24-debian12

WORKDIR /workspace/app

COPY --chown=65532:65532 --from=build /workspace/app /workspace/app
COPY --chown=65532:65532 --from=build /var/log/devops-app /var/log/devops-app

USER 65532:65532

EXPOSE 3000

CMD ["TODO-start-script"]
