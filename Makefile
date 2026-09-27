CLUSTER ?= laravel
NS      ?= laravel

.PHONY: up images deploy smoke lint down

up: ## Create a local k3d cluster, build images and deploy everything
	k3d cluster create $(CLUSTER) -p "80:80@loadbalancer" --wait
	$(MAKE) images deploy

images:
	docker build --target fpm -t laravel-on-k8s-fpm:local app
	docker build --target web -t laravel-on-k8s-web:local app
	k3d image import -c $(CLUSTER) laravel-on-k8s-fpm:local laravel-on-k8s-web:local

deploy:
	NS=$(NS) ./scripts/deploy.sh

smoke:
	NS=$(NS) ./scripts/smoke.sh

lint:
	helm lint charts/laravel-app -f values/api.yaml
	helm lint charts/laravel-app -f values/web.yaml

down:
	k3d cluster delete $(CLUSTER)
