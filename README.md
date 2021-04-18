# slu.gg

A url shortener

## Local

Add host port mappings in the `docker-compose.yml` for the nginx server (`80`) and (optionally) for the redis server (`6379`).

Run `docker-compose up --build` and navigate to the specified host port. Profit. Update code. `docker-compose up --build` again. Profit.