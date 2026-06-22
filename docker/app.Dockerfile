FROM node:24-bookworm-slim

WORKDIR /workspace

COPY app/package*.json ./app/

WORKDIR /workspace/app

RUN npm ci

COPY app ./ 

RUN mkdir -p /var/log/devops-app && chown -R node:node /var/log/devops-app /workspace/app

USER node

EXPOSE 3000

CMD ["npm", "TODO-start-script"]
