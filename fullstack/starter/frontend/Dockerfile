FROM node:20

WORKDIR /app

RUN npm install -g @angular/cli

# Create minimal Angular app
RUN ng new taskboard --defaults --skip-git && mv taskboard/* ./

CMD ["ng", "serve", "--host", "0.0.0.0"]
