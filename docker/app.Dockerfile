FROM node:24.14.0-bookworm-slim

WORKDIR /workspace

COPY app/package*.json ./app/

WORKDIR /workspace/app

RUN npm install -g npm@11.9.0 \
  && npm ci --omit=dev

COPY app ./ 

RUN mkdir -p /var/log/devops-app && chown -R node:node /var/log/devops-app /workspace/app

USER node

EXPOSE 3000

CMD ["npm", "TODO-start-script"]
