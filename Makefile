stable:
	docker build -f Dockerfile -t octopus .

develop:
	docker build --progress plain -f Dockerfile-develop -t octopus-develop .

.PHONY: stable develop dockerhub-update-13.0

dockerhub-update-13.0:
	docker build -f Dockerfile -t fangohr/octopus:13.0 .
	@echo "If the container has built successfully, do this to push to dockerhub:"
	@echo "Run 'docker login'"
	@echo "Run 'docker push fangohr/octopus:13.0'"
	@echo "Run 'docker tag fangohr/octopus:13.0 fangohr/octopus:latest'"
	@echo "Run 'docker push fangohr/octopus:latest'"
