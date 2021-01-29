log: 
	@env-cmd ts-node bot/$@.ts

bot:
	@env-cmd ts-node bot/$@.ts

g:
	@env-cmd ./$@.sh

migrate:
	@truffle migrate --network development --reset

remix:
	@remixd -s contracts

.PHONY: \
	log \
	bot \
	g \
	migrate \
	remix